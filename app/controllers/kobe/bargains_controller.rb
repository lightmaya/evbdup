# -*- encoding : utf-8 -*-
class Kobe::BargainsController < KobeController
  before_action :get_category, :only => [:new, :create]
  before_action :get_show_arr, :only => [:audit, :show, :confirm]
  before_action :get_audit_menu_ids, :only => [:list, :audit, :update_audit]
  before_action :get_audit_bargain, :only => [:audit, :update_audit]
  before_action :get_bargain, :except => [:index, :new, :create, :list, :show_optional_category, :show_optional_products, :check_choose_dep, :bid_list, :show_bid_details]

  skip_before_action :verify_authenticity_token, :only => [:commit, :show_optional_category, :check_choose_dep]
  skip_load_and_authorize_resource :only => [:show_optional_category, :check_choose_dep]

  # 辖区内协议议价
  def index
    params[:q][:user_id_eq] = current_user.id if ["my", "confirm"].include? params[:t]
    params[:q][:status_eq] = Bargain.confirm_status if params[:t] == "confirm"
    @q = Bargain.find_all_by_dep_code(current_user.real_dep_code).where(get_conditions("bargains")).ransack(params[:q])
    @bargains = @q.result.page params[:page]
  end

  def new
    @bargain.dep_name = @bargain.invoice_title = current_user.real_department.name
    @bargain.dep_man = current_user.name
    @bargain.dep_tel = current_user.tel
    @bargain.dep_mobile = current_user.mobile
    @bargain.dep_addr = current_user.department.address
    slave_objs = [@bargain.products.build]
    @myform = MasterSlaveForm.new(Bargain.xml,BargainProduct.xml(@category),@bargain,slave_objs,{form_id: 'new_bargain', upload_files: true, title: "<i class='fa fa-pencil-square-o'></i> 发起议价--#{@category.name}",action: kobe_bargains_path(c: @category.id, i: @item.id), grid: 3},{title: '产品明细', grid: 3})
  end

  def create
    other_attrs = { category_id: @category.id, category_code: @category.ancestry, item_id: @item.id,
      department_id: current_user.department.id, dep_code: current_user.real_dep_code,
      name: "#{current_user.real_department.name} #{Time.new.to_date.to_s} #{@category.name} 协议议价项目" }
    bargain = create_msform_and_write_logs(Bargain, Bargain.xml, BargainProduct, BargainProduct.xml(@category), {:action => "发起议价", :slave_title => "产品信息"}, other_attrs)
    redirect_to choose_kobe_bargain_path(bargain)
  end

  def update
    update_msform_and_write_logs(@bargain, Bargain.xml, BargainProduct, BargainProduct.xml(@bargain.category), {:action => "修改协议议价", :slave_title => "产品信息"})
    redirect_to choose_kobe_bargain_path(@bargain)
  end

  def edit
    slave_objs = @bargain.products.blank? ? [@bargain.products.build] : @bargain.products
    @myform = MasterSlaveForm.new(Bargain.xml,BargainProduct.xml(@bargain.category),@bargain,slave_objs,{form_id: 'new_bargain', upload_files: true, title: "<i class='fa fa-wrench'></i> 修改协议议价--#{@bargain.category.name}",action: kobe_bargain_path(@bargain), method: "patch", grid: 3},{title: '产品明细', grid: 3})
  end

  def show
  end

  # 提交
  def commit
    @bargain.change_status_and_write_logs("提交", stateless_logs("提交","提交成功！", false), @bargain.commit_params)
    # 插入协议议价审核的待办事项
    @bargain.reload.create_task_queue
    tips_get("提交成功！")
    redirect_back_or
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_bargain_form', action: kobe_bargain_path(@bargain), method: 'delete' }
  end

  def destroy
    @bargain.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_back_or request.referer
  end

  def list
    @bargains = audit_list(Bargain)
  end

  def audit

  end

  def update_audit
    save_audit(@bargain)
    # 插入order表

    redirect_to list_kobe_bargains_path
  end

  # 发起议价时选择品目
  def show_optional_category
    @items = Item.usable.where(is_classify: true)
    render layout: false
  end

  # 指定报价供应商
  def choose
    dep_ids = get_optional_dep_ids(@bargain)
    @deps = ItemDepartment.where(item_id: @bargain.item_id, department_id: dep_ids).order("if(classify=0, 99, classify)")
  end

  # 检查选择的供应商是否包含所有A级供应商
  def check_choose_dep
    render :text => include_a_dep(params[:b], params[:d])
  end

  def update_choose
    rs = false
    msg = ""
    unless include_a_dep(params[:b], params[:d])
      msg = Bargain.a_dep_tips
    else
      tmp = 0
      dep_ids = params[:d].split(",").map(&:to_i)

      # 删除不是本次选中的供应商id
      all_dep_ids = @bargain.bids.map(&:department_id)
      BargainBid.destroy_all(bargain_id: @bargain.id, department_id: (all_dep_ids - dep_ids))

      names = []
      dep_ids.each do |d|
        dep = Department.find_by(id: d)
        if dep.blank?
          tmp += 1
        else
          @bargain.bids.find_or_create_by(bargain_id: @bargain.id, department_id: d, name: dep.name)
          names << dep.name
        end
      end
      write_logs(@bargain, '选择报价供应商', "指定 [ #{names.join(', ')} ] #{names.size} 家供应商报价！")
      rs = true if tmp == 0
    end
    render :json => { rs: rs, msg: msg }
  end

  # 查看可报价的产品
  def show_optional_products
    @bargain = Bargain.find_by(id: params[:b])
    @dep = Department.find_by(id: params[:d])
    cannot_do_tips unless @bargain.present? && @dep.present? && current_user.real_department.is_ancestors?(@bargain.department_id)
    @products = []
    @bargain.products.each do |product|
      cdt = get_cdts_by_product_params(product)
      cdt << "department_id = #{@dep.id}"
      @products << Product.show.where(cdt.join(" and "))
    end
  end

  # 报价
  def bid
    @products = []
    @bargain.products.each do |product|
      cdt = get_cdts_by_product_params(product)
      cdt << "department_id = #{current_user.department.id}"
      @products << Product.show.where(cdt.join(" and "))
    end

    @bid = @bargain.bids.find_by(department_id: current_user.real_department.id)
  end

  def update_bid
    bid = @bargain.bids.find_by(department_id: params[:department_id])
    cannot_do_tips if bid.blank?

    @bargain.products.each do |product|
      p_id = params["pid_#{product.id}"]
      price = params["price_#{product.id}_#{p_id}"]
      bid_product = bid.products.find_by(bargain_product_id: product.id)
      if bid_product.present?
        bid_product.update(product_id: p_id, price: price, total: (product.quantity * price.to_f))
      else
        bid.products.create(bargain_product_id: product.id, product_id: p_id, price: price, total: (product.quantity * price.to_f))
      end
    end
    info = bid.has_bid? ? "修改报价" : "报价"
    bid_time = bid.has_bid? ? bid.bid_time : Time.now
    update_and_write_logs(bid, BargainBid.xml, {}, { user_id: current_user.id, bid_time: bid_time })
    write_logs(@bargain, info, "[#{bid.name}]#{info}成功！")
    # 删除待办事项
    TaskQueue.where(class_name: 'Bargain', obj_id: @bargain.id, dep_id: bid.department_id).destroy_all if info == "报价"

    redirect_to bid_list_kobe_bargains_path(flag: 2)
  end

  # 报价列表
  def bid_list
    params[:flag] ||= "1"
    case params[:flag]
    when "1" # 可报价
      @panel_title = "可报价的协议议价项目"
      params[:q][:bids_total_eq] = 0
    when "2" # 已投标
      @panel_title = "已报价的协议议价项目"
      params[:q][:bids_total_not_eq] = 0
    when "3" # 已中标
      @panel_title = "已中标的协议议价项目"
      params[:q][:bids_is_bid_eq] = true
    end
    params[:q][:bids_department_id_eq] = current_user.department.id
    @q = Bargain.ransack(params[:q])
    @bargains = @q.result.includes(:bids).page params[:page]
  end

  # 查看已报价的产品
  def show_bid_details
    @bargain = Bargain.find_by(id: params[:b])
    @dep = Department.find_by(id: params[:d])
    cannot_do_tips unless @bargain.present? && @dep.present? && current_user.real_department.is_ancestors?(@bargain.department_id)
    @bid = @bargain.bids.find_by(department_id: @dep.id)
    # @products = []
    # @bargain.products.each do |product|
    #   cdt = get_cdts_by_product_params(product)
    #   cdt << "department_id = #{@dep.id}"
    #   @products << Product.show.where(cdt.join(" and "))
    # end
  end

  # 确认结果
  def confirm
    @myform = SingleForm.new(Bargain.confirm_xml, @bargain, { form_id: "confirm_form", upload_files: true, action: update_confirm_kobe_bargain_path(@bargain), title: '选择中标人' })
  end

  def update_confirm
    cs = @bargain.get_current_step
    if cs.is_a?(Hash)
      ns = @bargain.get_next_step
      rule_step = ns.is_a?(Hash) ? ns["name"] : ns
      st = @bargain.get_change_status("通过")
      update_and_write_logs(@bargain, Bargain.confirm_xml, { action: '选择中标人' }, { status: st, rule_step: rule_step })
      bid = @bargain.bids.find_by(id: params[:bargains][:bid_id])
      bid.update(is_bid: true) if bid.present?
      # 插入协议议价审核的待办事项
      @bargain.reload.create_task_queue
    end
    redirect_to kobe_bargains_path(t: "my")
  end

  private
    # 检查选择的供应商是否包含所有A级供应商
    # bargain_id: 协议议价的id  department_ids: 所选择的供应商id拼成的字符串 例如：“123, 142, 2345, 311”
    def include_a_dep(bargain_id, department_ids)
      bargain = Bargain.find_by(id: bargain_id)
      dep_ids = get_optional_dep_ids(bargain)
      a_deps = ItemDepartment.where(item_id: bargain.item_id, classify: 1, department_id: dep_ids).map(&:department_id)
      choose_deps = department_ids.split(",").map(&:to_i)
      return (a_deps & choose_deps) == a_deps
    end

    # 符合产品参数的供应商ID
    def get_optional_dep_ids(bargain)
      dep_ids = []
      bargain.products.each_with_index do |product, index|
        cdt = get_cdts_by_product_params(product)
        cdt << "category_id = #{bargain.category_id}"
        d_ids = Product.show.where(cdt.join(" and ")).map(&:department_id)
        dep_ids = index == 0 ? d_ids : (dep_ids & d_ids)
      end
      return dep_ids
    end

    # 根据选择的产品参数组成sql条件 返回数组
    def get_cdts_by_product_params(product)
      Nokogiri::XML(product.details).css("node").map{ |n|
        %Q|extractvalue(details, '//node[@name=\"#{n["name"]}\"]/@value') = '#{n["value"]}'| }
    end

    def get_audit_menu_ids
      @menu_ids = Menu.get_menu_ids("Bargain|list")
    end

    def get_audit_bargain
      @bargain = Bargain.find_by(id: params[:id]) if params[:id].present?
      audit_tips unless @bargain.present? && @bargain.cando(action_name,current_user) && can_audit?(@bargain,@menu_ids)
    end

    def get_category
      @category = Category.find_by(id: params[:c]) if params[:c].present?
      @item = Item.find_by(id: params[:i]) if params[:i].present?
      cannot_do_tips if @category.blank? || @item.blank?
    end

    def get_bargain
      cannot_do_tips unless @bargain.present? && @bargain.cando(action_name,current_user)
      audit_tips  if ['audit', 'update_audit'].include?(action_name) && !can_audit?(@bargain,@menu_ids)
    end

    def get_show_arr
      obj_contents = show_obj_info(@bargain,Bargain.xml)
      @bargain.products.each_with_index do |p, index|
        obj_contents << show_obj_info(p,BargainProduct.xml(@bargain.category),{title: "产品明细 ##{index+1}", grid: 3})
      end
      @arr  = []
      @arr << {title: "详细信息", icon: "fa-info", content: obj_contents}

     @arr << get_budget_hash(@bargain.budget, @bargain.department_id)

      @arr << {title: "附件", icon: "fa-paperclip", content: show_uploads(@bargain)}
      @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@bargain, @bargain.show_logs)}
    end

end
