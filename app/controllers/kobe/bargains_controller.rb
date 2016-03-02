# -*- encoding : utf-8 -*-
class Kobe::BargainsController < KobeController
  before_action :get_category, :only => [:new, :create]
  before_action :get_show_arr, :only => [:audit, :show]
  before_action :get_audit_menu_ids, :only => [:list, :audit, :update_audit]
  before_action :get_audit_bargain, :only => [:audit, :update_audit]
  before_action :get_bargain, :except => [:index, :new, :create, :list, :show_optional_category]

  skip_before_action :verify_authenticity_token, :only => [:commit, :show_optional_category]
  skip_load_and_authorize_resource :only => :show_optional_category

  # 辖区内协议议价
  def index
    params[:q][:user_id_eq] = current_user.id if params[:t] == "my"
    @q = Bargain.find_all_by_dep_code(current_user.real_dep_code).where(get_conditions("bargains")).ransack(params[:q])
    @bargains = @q.result.page params[:page]
  end

  def new
    @bargain.dep_name = current_user.real_department.name
    @bargain.dep_man = current_user.name
    @bargain.dep_tel = current_user.tel
    @bargain.dep_mobile = current_user.mobile
    slave_objs = [@bargain.products.build]
    @myform = MasterSlaveForm.new(Bargain.xml,BargainProduct.xml(@category),@bargain,slave_objs,{form_id: 'new_bargain', upload_files: true, title: "<i class='fa fa-pencil-square-o'></i> 发起议价--#{@category.name}",action: kobe_bargains_path(category_id: @category.id), grid: 3},{title: '产品明细', grid: 3})
  end

  def create
    other_attrs = { category_id: @category.id, category_code: @category.ancestry,
      department_id: current_user.department.id, dep_code: current_user.real_dep_code,
      name: "#{current_user.real_department.name} #{Time.new.to_date.to_s} #{@category.name} 协议议价项目" }
    create_msform_and_write_logs(Bargain, Bargain.xml, BargainProduct, BargainProduct.xml(@category), {:action => "发起议价", :slave_title => "产品信息"}, other_attrs)
    redirect_to kobe_bargains_path(t: "my")
  end

  def update
    update_msform_and_write_logs(@bargain, Bargain.xml, BargainProduct, BargainProduct.xml(@bargain.category), {:action => "修改协议议价", :slave_title => "产品信息"})
    redirect_to kobe_bargains_path(t: "my")
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
    redirect_to list_kobe_bargains_path
  end

  def show_optional_category
    @categories = Item.usable.where(is_classify: true).map(&:categories).flatten
    render layout: false
  end

  private

    def get_audit_menu_ids
      @menu_ids = Menu.get_menu_ids("Bargain|list")
    end

    def get_audit_bargain
      @bargain = Bargain.find_by(id: params[:id]) if params[:id].present?
      audit_tips unless @bargain.present? && @bargain.cando(action_name,current_user) && can_audit?(@bargain,@menu_ids)
    end

    def get_category
      @category = Category.find_by(id: params[:category_id]) if params[:category_id].present?
      cannot_do_tips if @category.blank?
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
      @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@bargain)}
    end

end
