# -*- encoding : utf-8 -*-
class Kobe::OrdersController < KobeController

  before_action :get_order, :only => [:show, :edit, :update, :destroy, :commit, :print]
  before_action :get_show_arr, :only => [:audit, :show]
  before_action :check_same_template, :only => [:create, :update]
  skip_before_action :verify_authenticity_token, :only => [:same_template, :commit]
  before_action :get_audit_menu_ids, :only => [:list, :audit, :update_audit]

  skip_authorize_resource :only => [:same_template]

  before_filter :order_from_cart, :only => [:cart_order, :create_cart_order]
  # 辖区内采购项目
  def index
    @q = Order.find_all_by_buyer_code(current_user.real_dep_code).where(get_conditions("orders")).not_grcg.ransack(params[:q]) 
    @orders = @q.result.page params[:page]
  end

  def new
    @order = Order.init_order(current_user, 'ddcg')
   #  @order.yw_type = 'ddcg'
  	# @order.buyer_name = @order.payer = current_user.real_department.name
   #  @order.buyer_man = current_user.name
   #  @order.buyer_tel = current_user.tel
   #  @order.buyer_mobile = current_user.mobile
   #  @order.buyer_addr = current_user.department.address
    slave_objs = [OrdersItem.new(order_id: @order.id)]
    @ms_form = MasterSlaveForm.new(Order.xml,OrdersItem.xml,@order,slave_objs,{form_id: 'new_order', upload_files: true, min_number_of_files: 1, title: '<i class="fa fa-pencil-square-o"></i> 下单',action: kobe_orders_path, show_total: true, grid: 4},{title: '产品明细', grid: 4})
  end

  def show
  end

  def create
    other_attrs = { 
      buyer_id: current_user.department.id, buyer_code: current_user.real_dep_code, 
      name: Order.get_project_name(nil, current_user, params[:orders_items][:category_name].values.uniq.join("、"), params[:orders][:yw_type]) 
    }
    @order = create_msform_and_write_logs(Order, Order.xml, OrdersItem, OrdersItem.xml, {:action => "下单", :master_title => "基本信息",:slave_title => "产品信息"}, other_attrs)
    unless @order.id
      redirect_back_or
    else
      redirect_to my_list_kobe_orders_path(r: @order.rule.try(:id))
    end
  end

  # 供应商确认页面
  def agent_confirm_pre
    @order = Order.by_seller_id(current_user.real_department.id).find_by_id(params[:id])
    return redirect_to(not_found_path) unless @order
    slave_objs = @order.items
    @ms_form = MasterSlaveForm.new(Order.agent_xml, OrdersItem.confirm_xml, @order, slave_objs, 
      {title: "基本信息", action: agent_confirm_kobe_order_path(id: @order.id), show_total: true, grid: 4},
      {title: '产品明细', grid: 4, modify: false}
    )
  end

  # 供应商确认
  def agent_confirm
    @order = Order.by_seller_id(current_user.real_department.id).find_by_id(params[:id])
    return redirect_to(not_found_path) unless @order
    @order = create_or_update_msform_and_write_logs(@order, Order.agent_xml, OrdersItem, OrdersItem.confirm_xml, {:action => "供应商确认", :master_title => "基本信息", :slave_title => "产品信息"})
    write_logs(@order, "供应商确认", "")
    redirect_to seller_list_kobe_orders_path(r: @order.rule.try(:id))
  end

  # 采购人确认页面
  def buyer_confirm_pre
    @order = current_user.orders.find_by_id(params[:id])
    return redirect_to(not_found_path) unless @order
    slave_objs = @order.items
    @ms_form = MasterSlaveForm.new(Order.buyer_xml, OrdersItem.confirm_xml, @order, slave_objs, 
      {title: "基本信息", action: agent_confirm_kobe_order_path(id: @order.id), show_total: true, grid: 4},
      {title: '产品明细', grid: 4, modify: false}
    )
  end

  # 采购人确认
  def buyer_confirm
    @order = current_user.orders.find_by_id(params[:id])
    return redirect_to(not_found_path) unless @order
    @order = create_or_update_msform_and_write_logs(@order, Order.agent_xml, OrdersItem, OrdersItem.confirm_xml, {:action => "供应商确认", :master_title => "基本信息", :slave_title => "产品信息"})
    write_logs(@order, "采购人确认", "")
    redirect_to my_list_kobe_orders_path(r: @order.rule.try(:id))
  end

  # 下单
  def create_cart_order
    begin
      if @order.save
        # 清理购物车
        # @order.items.each{|item| @cart.destroy(item.product_id, item.seller_id)}
        # current_user.update(cart: @cart.to_yaml)
        return render :json => {"success" => true}
      else
        return render :json => {"success" => false, "msg" => "订单保存失败: #{@order.errors.full_messages}"}
      end 
    rescue Exception => e
      return render :json => {"success" => false, "msg" => "订单保存失败！#{e}"}
    end
  end

  #  下单页面
  def cart_order
    @budgets = current_user.valid_budgets
  end

  def update
    update_msform_and_write_logs(@order, Order.xml, OrdersItem, OrdersItem.xml, {:action => "修改订单", :master_title => "基本信息",:slave_title => "产品信息"}, { name: Order.get_project_name(@order, current_user, params[:orders_items][:category_name].values.uniq.join("、"), params[:orders][:yw_type]) })
    redirect_to my_list_kobe_orders_path(r: @order.rule.try(:id))
  end

  def edit
    slave_objs = @order.items.blank? ? [OrdersItem.new(order_id: @order.id)] : @order.items
    @ms_form = MasterSlaveForm.new(Order.xml,OrdersItem.xml,@order,slave_objs,{form_id: 'new_order', upload_files: true, min_number_of_files: 1, title: '<i class="fa fa-wrench"></i> 修改订单',action: kobe_order_path(@order), method: "patch", show_total: true, grid: 4},{title: '产品明细', grid: 4})
  end

  # 提交
  def commit
    remark = @order.find_step_by_rule.blank? ? "提交成功！项目已生效。" : "提交成功！请等待#{@order.find_step_by_rule["name"]}。"
    logs = stateless_logs("提交",remark, false)
    c_arr = @order.commit_params
    c_arr << "ht_template = '#{@order.get_ht_template}'"
    @order.change_status_and_write_logs("提交", logs, c_arr, false)
    @order.reload.create_task_queue
    tips_get(remark)
    redirect_to my_list_kobe_orders_path(r: @order.rule.try(:id))
  end

  # 审核订单
  def list
    @rule = Rule.find_by(id: params[:r]) if params[:r].present?
    arr = @rule.present? ? [["orders.yw_type = ? ", @rule.yw_type]] : []
    @orders = audit_list(Order, arr)
  end

  # 我的订单
  def my_list
    @rule = Rule.find_by(id: params[:r])
    params[:q][:user_id_eq] = current_user.id
    params[:q][:yw_type_eq] = @rule.try(:yw_type)
    @q = Order.where(get_conditions("orders")).ransack(params[:q]) 
    @orders = @q.result.page params[:page]
  end

  # 销售项目列表 供应商的订单中心
  def seller_list
    @rule = Rule.find_by(id: params[:r])
    params[:q][:yw_type_eq] = @rule.try(:yw_type)
    @q = Order.find_all_by_seller(current_user.real_department.id, current_user.real_department.name).where(get_conditions("orders")).ransack(params[:q]) 
    @orders = @q.result.page params[:page]
  end

  def audit
  end

  def update_audit
    save_audit(@order)
    redirect_to list_kobe_orders_path(r: @order.rule.try(:id))
  end

  # 根据category_id判断模版是否相同
  def same_template
    templates = get_templates(params[:category_ids].split(","))
    render :text => templates.size
  end

  def print_ht
    str = "合同编号：#{@order.contract_sn}"
    str << "，合计金额：#{@order.total}元，验证网址：http://fwgs.sinograin.com.cn/c/#{@order.contract_sn}?m=#{@order.total}"
    @qr = qrcode(str)
    render partial: @order.ht , layout: 'print'  
  end
  
  def print_ysd
    str = "凭证编号：#{@order.sn}"
    str << "，合计金额：#{@order.total}元，验证网址：http://fwgs.sinograin.com.cn/c/#{@order.sn}?m=#{@order.total}"
    @qr = qrcode(str)
    render  partial: 'print_ysd',layout: 'print'  
  end

  def print
    render layout: false
  end
  
  def invoice_number
    render layout: false 
  end

  def update_invoice_number
     @order.update(invoice_number: params[:number] )
     write_logs(@order, '填写发票')
     redirect_to my_list_kobe_orders_path(r: @order.rule.try(:id))
  end

  private

    def get_audit_menu_ids
      @menu_ids = Menu.get_menu_ids("Order|#{action_name}")
    end

    def get_order
      cannot_do_tips unless @order.present? && @order.cando(action_name,current_user)
      # menu_ids = Menu.get_menu_ids("Order|audit_#{@order.yw_type}") if @order.present?
      audit_tips  if ['audit', 'update_audit'].include?(action_name) && !can_audit?(@order, @menu_ids)
    end

    # show页面的数组
    def get_show_arr
      obj_contents = show_obj_info(@order,Order.xml,{title: "基本信息"})
      @order.items.each_with_index do |item, index|
        obj_contents << show_obj_info(item,OrdersItem.xml,{title: "产品明细 ##{index+1}"})
      end
      obj_contents << show_obj_info(@order,Order.fee_xml,{title: "附加费用", grid: 3})
      obj_contents << show_total_part(@order.total)
      @arr  = []
      @arr << {title: "详细信息", icon: "fa-info", content: obj_contents}

      budget = @order.budget
      if budget.present? && current_user.real_department.is_ancestors?(@order.buyer_id)
        budget_contents = show_obj_info(budget, Budget.xml)
        budget_contents << show_uploads(budget, { is_picture: true })
        @arr << { title: "预算审批单", icon: "fa-paperclip", content: budget_contents }
      end

      @arr << {title: "附件", icon: "fa-paperclip", content: show_uploads(@order)}
      # @arr << {title: "评价", icon: "fa-star-half-o", content: show_estimates(@order)}
      @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@order)}
    end

    # 判断是不是同一个模板
    def check_same_template
      templates = get_templates(params[:orders_items][:category_id].values)
      cannot_do_tips("请选择同一大类的品目!") unless templates.size == 1
    end

    # 获取模版
    def get_templates(category_ids)
      Category.where(id: category_ids).map(&:ht_template).uniq
    end

    def order_from_cart
      return redirect_to cart_path if @cart.ready_items.blank?

      unless @cart.same_seller?
        tips_get("请选择同一供应商的商品")
        return redirect_to cart_path
      end

      unless @cart.same_ht?
        tips_get("请选择同一合同模板品目的商品")
        return redirect_to cart_path
      end

      @order = if action_name == "create_cart_order"
        Order.from(@cart, current_user, params)
      else
        Order.from(@cart, current_user)
      end 
    end
end
