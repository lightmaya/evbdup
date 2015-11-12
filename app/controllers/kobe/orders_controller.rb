# -*- encoding : utf-8 -*-
class Kobe::OrdersController < KobeController

  before_action :get_order, :only => [:show, :edit, :update, :destroy, :commit, :print]
  before_action :get_show_arr, :only => [:audit, :show]
  before_action :check_same_template, :only => [:create, :update]
  skip_before_action :verify_authenticity_token, :only => [:same_template, :commit]

  skip_authorize_resource :only => [:same_template]

  # 辖区内采购项目
  def index
    @q = Order.find_all_by_buyer_code(current_user.department.real_ancestry).where(get_conditions("orders")).ransack(params[:q]) 
    @orders = @q.result.page params[:page]
  end

  def new
    @order = Order.init_order(current_user)
    slave_objs = [OrdersItem.new(order_id: @order.id)]
    @ms_form = MasterSlaveForm.new(Order.xml, OrdersItem.xml, @order,slave_objs,{form_id: 'new_order', upload_files: true, min_number_of_files: 1, title: '<i class="fa fa-pencil-square-o"></i> 下单',action: kobe_orders_path, show_total: true, grid: 4},{title: '产品明细', grid: 4})
  end

  def show
  end

  def create
    other_attrs = { buyer_id: current_user.department.id, buyer_code: current_user.department.real_ancestry, name: Order.get_project_name(nil, current_user, params[:orders_items][:category_name].values.uniq.join("、")) }
    @order = create_msform_and_write_logs(Order, Order.xml, OrdersItem, OrdersItem.xml, {:action => "下单", :master_title => "基本信息",:slave_title => "产品信息"}, other_attrs)
    unless @order.id
      redirect_back_or
    else
      redirect_to eval("#{@order.yw_type}_list_kobe_orders_path")
    end
  end

  def cart_order
    if params[:check].blank?
      tips_get("请勾选购买商品")
      return redirect_to :back
    end
    
    @order = Order.init_order(current_user)
   
    params[:check].each do |product_id|
      if item = @cart.items.find{|item| item.product_id.to_i == product_id}
        product = item.product
        next unless product.show
        order_item = @order.items.build(category_id: product.category_id, 
          product_id: product_id, brand: product.brand, model: product.model, version: product.version,
          unit: product.unit, market_price: product.market_price,
          bid_price: product.bid_price,
          price: params["real_price_cart_item_#{product_id}"].to_f,
          quantity: [params["cart_item_#{product_id}"].to_i, 1].max
        )
      end
    end

    slave_objs = [@order.items]
    @ms_form = MasterSlaveForm.new(Order.xml, OrdersItem.xml, @order,slave_objs,{form_id: 'new_order', upload_files: true, min_number_of_files: 1, title: '<i class="fa fa-pencil-square-o"></i> 下单',action: kobe_orders_path, show_total: true, grid: 4},{title: '产品明细', grid: 4})
  

    # if @order.save
    #   redirect_to edit_kobe_order_path(@order)
    # else

    #   tips_get("下单失败，请稍后重试")
    #   redirect_to :back
    # end
  end

  def update
    update_msform_and_write_logs(@order, Order.xml, OrdersItem, OrdersItem.xml, {:action => "修改订单", :master_title => "基本信息",:slave_title => "产品信息"}, { name: Order.get_project_name(@order, current_user, params[:orders_items][:category_name].values.uniq.join("、")) })
    redirect_to eval("#{@order.yw_type}_list_kobe_orders_path")
  end

  def edit
    slave_objs = @order.items.blank? ? [OrdersItem.new(order_id: @order.id)] : @order.items
    @ms_form = MasterSlaveForm.new(Order.xml,OrdersItem.xml,@order,slave_objs,{form_id: 'new_order', upload_files: true, min_number_of_files: 1, title: '<i class="fa fa-wrench"></i> 修改订单',action: kobe_order_path(@order), method: "patch", show_total: true, grid: 4},{title: '产品明细', grid: 4})
  end

  # 提交
  def commit
    remark = @order.find_step_by_rule.blank? ? "提交成功！项目已生效。" : "提交成功！请等待#{@order.find_step_by_rule["name"]}。"
    logs = stateless_logs("提交",remark, false)
    @order.change_status_and_write_logs("提交",logs,@order.commit_params, false)
    @order.reload.create_task_queue
    tips_get(remark)
    redirect_to eval("#{@order.yw_type}_list_kobe_orders_path")
  end

  # 审核定点采购项目
  def audit_ddcg
    arr = []
    arr << ["orders.yw_type = ? ", 'ddcg']
    audit_list(arr)
  end
  

  # 我的定点采购项目
  def ddcg_list
    params[:q][:user_id_eq] = current_user.id
    params[:q][:yw_type_eq] = 'ddcg'
    @q = Order.where(get_conditions("orders")).ransack(params[:q]) 
    @orders = @q.result.page params[:page]
  end

  def audit
  end

  def update_audit
    save_audit(@order)
    redirect_to eval("audit_#{@order.yw_type}_kobe_orders_path")
  end

  # 根据category_id判断模版是否相同
  def same_template
    templates = get_templates(params[:category_ids].split(","))
    render :text => templates.size
  end

  def print
    render partial: @order.ht
  end

  private

    def get_order
      cannot_do_tips unless @order.present? && @order.cando(action_name,current_user)
      menu_ids = Menu.get_menu_ids("Order|audit_#{@order.yw_type}") if @order.present?
      audit_tips  if ['audit', 'update_audit'].include?(action_name) && !can_audit?(@order, menu_ids)
    end


 
    # show页面的数组
    def get_show_arr
      obj_contents = show_obj_info(@order,Order.xml,{title: "基本信息"})
      @order.items.each_with_index do |item, index|
        obj_contents << show_obj_info(item,OrdersItem.xml,{title: "产品明细 ##{index+1}"})
      end
      @arr  = []
      @arr << {title: "详细信息", icon: "fa-info", content: obj_contents}
      @arr << {title: "附件", icon: "fa-paperclip", content: show_uploads(@order)}
      @arr << {title: "评价", icon: "fa-star-half-o", content: show_estimates(@order)}
      @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@order)}
    end

    # 判断是不是同一个模板
    def check_same_template
      templates = get_templates(params[:orders_items][:category_id].values)
      cannot_do_tips("请选择同一类品目!") unless templates.size == 1
    end

    # 获取模版
    def get_templates(category_ids)
      Category.where(id: category_ids).map(&:ht_template).uniq
    end

    # 审核
    def audit_list(arr=[])
      menu_ids = Menu.get_menu_ids("Order|#{action_name}")
      arr << ["orders.status = ? ", 1]
      arr << ["(task_queues.user_id = ? or task_queues.menu_id in (#{menu_ids.join(",") }) )", current_user.id]
      arr << ["task_queues.dep_id = ?", current_user.real_department.id]
      @q =  Order.joins(:task_queues).where(get_conditions("orders", arr)).ransack(params[:q])
      @orders = @q.result(distinct: true).page params[:page]
    end
end
