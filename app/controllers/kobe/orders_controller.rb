# -*- encoding : utf-8 -*-
class Kobe::OrdersController < KobeController

  before_action :get_show_arr, :only => [:audit, :show]
  before_action :check_same_template, :only => [:create, :update]
  skip_before_action :verify_authenticity_token, :only => [:same_template, :commit]
  before_action :get_audit_menu_ids, :only => [:list, :audit, :update_audit]
  before_action :get_order, :except => [:index, :new, :create, :cart_order, :update_cart_order, :list, :my_list, :grcg_list, :seller_list, :same_template]

  skip_authorize_resource :only => [:same_template]

  before_filter :order_from_cart, :only => [:cart_order, :update_cart_order]
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
  def agent_confirm
    @order = Order.by_seller_id(current_user.real_department.id).find_by_id(params[:id])
    # return redirect_to(not_found_path) unless @order
    cannot_do_tips unless @order.present? && @order.cando(action_name,current_user)
    slave_objs = @order.items
    @ms_form = MasterSlaveForm.new(Order.agent_xml, OrdersItem.confirm_xml, @order, slave_objs,
      {form_id: 'agent_confirm_order', title: "基本信息", action: update_agent_confirm_kobe_order_path(id: @order.id), show_total: true, grid: 4},
      {title: '产品明细', grid: 4, modify: false}
    )
  end

  # 供应商确认
  def update_agent_confirm
    @order = Order.by_seller_id(current_user.real_department.id).find_by_id(params[:id])
    # return redirect_to(not_found_path) unless @order
    cannot_do_tips unless @order.present? && @order.cando(action_name,current_user)
    # @order = create_or_update_msform_and_write_logs(@order, Order.agent_xml, OrdersItem, OrdersItem.confirm_xml, {:action => "供应商确认", :master_title => "基本信息", :slave_title => "产品信息"})
    update_confirm_and_write_logs(Order.agent_xml, OrdersItem.confirm_xml)
    redirect_to seller_list_kobe_orders_path(r: @order.rule.try(:id))
  end

  # 采购人确认页面
  def buyer_confirm
    @order = current_user.orders.find_by_id(params[:id])
    # return redirect_to(not_found_path) unless @order
    cannot_do_tips unless @order.present? && @order.cando(action_name,current_user)
    slave_objs = @order.items
    @ms_form = MasterSlaveForm.new(Order.buyer_xml, OrdersItem.confirm_xml, @order, slave_objs,
      {form_id: 'buyer_confirm_order', title: "基本信息", action: update_buyer_confirm_kobe_order_path(id: @order.id), show_total: true, grid: 4},
      {title: '产品明细', grid: 4, modify: false}
    )
  end

  # 采购人确认
  def update_buyer_confirm
    @order = current_user.orders.find_by_id(params[:id])
    # return redirect_to(not_found_path) unless @order
    cannot_do_tips unless @order.present? && @order.cando(action_name,current_user)
    # @order = create_or_update_msform_and_write_logs(@order, Order.buyer_xml, OrdersItem, OrdersItem.confirm_xml, {:action => "供应商确认", :master_title => "基本信息", :slave_title => "产品信息"})
    # write_logs(@order, "采购人确认", "")
    update_confirm_and_write_logs(Order.buyer_xml, OrdersItem.confirm_xml)
    redirect_to my_list_kobe_orders_path(r: @order.rule.try(:id))
  end

  # 下单
  def update_cart_order
    begin
      if @order.save
        # 购物车的订单下单后直接按照流程 到供应商确认 不用修改和提交
        status = @order.get_change_status("提交")
        rule = @order.find_step_by_rule
        rule_step = rule.blank? ? "done" : "start"
        ht_template = @order.get_ht_template
        @order.update(status: status, rule_step: rule_step, ht_template: ht_template)
        @order.reload.create_task_queue
        # 写日志
        write_logs(@order, "下单", "购物车下单成功！#{"请等待#{rule['name']}" if rule.present?}")
        # 清理购物车
        save_cart
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

  # 全部个人采购订单
  def grcg_list
    params[:q][:yw_type_eq] = 'grcg'
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
     write_logs(@order, '填写发票', "发票号：#{params[:number]}")
     redirect_back_or request.referer
  end

  private

    def get_audit_menu_ids
      r = params[:r] if params[:r].present?
      r = @order.rule.try(:id) if @order.present?
      @menu_ids = Menu.get_menu_ids("Order|list_r#{r}")
    end

    def get_order
      cannot_do_tips unless @order.present? && @order.cando(action_name,current_user)
      # menu_ids = Menu.get_menu_ids("Order|audit_#{@order.yw_type}") if @order.present?
      audit_tips  if ['audit', 'update_audit'].include?(action_name) && !can_audit?(@order, @menu_ids)
    end

    # show页面的数组
    def get_show_arr
      obj_contents = show_obj_info(@order,Order.xml,{title: "基本信息", grid: 3})
      @order.items.each_with_index do |item, index|
        obj_contents << show_obj_info(item,OrdersItem.xml,{title: "产品明细 ##{index+1}", grid: 4})
      end
      obj_contents << show_obj_info(@order,Order.fee_xml,{title: "附加费用", grid: 3})
      obj_contents << show_total_part(@order.total)
      @arr  = []
      @arr << {title: "详细信息", icon: "fa-info", content: obj_contents}

      @arr << get_budget_hash(@order.budget, @order.buyer_id)
      # budget = @order.budget
      # if budget.present? && current_user.real_department.is_ancestors?(@order.buyer_id)
      #   budget_contents = show_obj_info(budget, Budget.xml)
      #   budget_contents << show_uploads(budget)
      #   @arr << { title: "预算审批单", icon: "fa-paperclip", content: budget_contents }
      # end

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

      @order = if action_name == "update_cart_order"
        Order.from(@cart, current_user, params)
      else
        Order.from(@cart, current_user)
      end
    end

    # 确认订单并写日志
    def update_confirm_and_write_logs(master_xml, slave_xml)
      cs = @order.get_current_step
      act = cs.is_a?(Hash) ? cs["name"] : "确认订单"
      master_title = "基本信息"
      slave_title = "产品信息"
      attribute = prepare_params_for_save(Order,master_xml) # 获取并整合主表参数信息
      # 保存附加费用
      if Order.respond_to?(:fee_xml)
        attribute = attribute.merge(prepare_params_for_save(Order, Order.fee_xml))
      end
      logs_remark = prepare_edit_logs_remark(@order,master_xml,"修改#{master_title}") #主表日志--修改痕迹 先取日志再更新主表，否则无法判断修改前后的变化情况
      if @order.update_attributes(attribute) #更新主表
        logs_remark << save_slaves(@order,OrdersItem,slave_xml,slave_title) # 保存从表并将日志添加到主表日志
        # "audit_yijian"=>"通过", "audit_liyou"=>"", "audit_next"=>"next"
        tips = "确认#{params[:audit_yijian]}。"
        tips << "操作理由：#{params[:audit_liyou]}" if params[:audit_liyou].present?
        remark = tips.clone
        remark << logs_remark if logs_remark.present?
        logs = stateless_logs(act, remark, false)
        if params[:audit_yijian] == "通过"
          go_to_audit_next(@order, logs)
        else
          ps = @order.get_prev_step
          rule_step = ps.is_a?(Hash) ? ps["name"] : ps
          @order.change_status_and_write_logs(params[:audit_yijian],logs,["rule_step = '#{rule_step}'"],false)
          # 插入待办事项
          @order.reload.create_task_queue
        end
        tips_get(tips)
      else
        flash_get(@order.errors.full_messages)
      end
    end

end
