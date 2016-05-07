# -*- encoding : utf-8 -*-
class Kobe::PlansController < KobeController
  before_action :get_item, :only => [:new, :create]
  before_action :get_category, :only => [:new, :create, :order]
  before_action :get_show_arr, :only => [:audit, :show]
  before_action :get_audit_menu_ids, :only => [:list, :audit, :update_audit]
  before_action :get_audit_plan, :only => [:audit, :update_audit]
  before_action :get_plan, :except => [:index, :new, :create, :list, :show_item_category, :show_order_item_category, :order, :update_order, :order_list, :bid_dep_ztree_json]

  skip_before_action :verify_authenticity_token, :only => [:commit, :show_item_category, :show_order_item_category]
  skip_load_and_authorize_resource only: [:show_item_category, :show_order_item_category, :bid_dep_ztree_json]

  # 报送结果
  def order
    @order = Order.init_order(current_user, 'jhcg')
    @order.plan_key = "#{params[:item_id]}_#{params[:category_id]}"
    slave_objs = [@order.items.build(category_id: @category.id, category_name: @category.name)]
    @ms_form = MasterSlaveForm.new(Order.xml(@order, current_user), OrdersItem.xml(@order, current_user),
      @order,slave_objs, { form_id: 'new_order', upload_files: true, title: "<i class=\"fa fa-pencil-square-o\"></i> 报送计划采购结果 -- #{@category.name}",
        action: update_order_kobe_plans_path, show_total: true, grid: 4 },
        { title: '产品明细', grid: 4 })
  end

  def update_order
    @order = Order.init_order(current_user, 'jhcg')
    arr = params[:orders][:plan_key].split("_")
    plan_item_id = arr[0]
    category_id = arr[1]
    @order.plan_key = params[:orders][:plan_key]
    category = Category.find_by(id: category_id)
    other_attrs = {
      buyer_id: current_user.department.id, buyer_code: current_user.real_dep_code,
      name: Order.get_project_name(nil, current_user, category.try(:name), 'jhcg')
    }
    @order = create_msform_and_write_logs(Order, Order.xml(@order, current_user),
      OrdersItem, OrdersItem.xml(@order, current_user),
      { :action => "下单", :master_title => "基本信息", :slave_title => "产品信息" }, other_attrs)
    @order.items.update_all(category_id: category.id, category_name: category.name)
    unless @order.id
      redirect_back_or
    else
      redirect_to order_list_kobe_plans_path
    end
  end

  # 计划采购中标供应商
  def bid_dep_ztree_json
    json = []
    deps = params[:ajax_key].present? ? PlanItemCategory.where(["plan_item_id = ? and category_id = ? and dep_name like ? ", params[:item_id], params[:category_id], "%#{params[:ajax_key]}%"]) : PlanItemCategory.where(plan_item_id: params[:item_id], category_id: params[:category_id])
    deps.each { |d| json << %Q|{"id":#{d.department_id.present? ? d.department_id : -1}, "pId": #{d.plan_item_id}, "name":"#{d.dep_name}"}| }
    render :json => "[#{json.join(", ")}]"
  end

  # 新增结果时 显示项目和品目
  def show_order_item_category
    @items = get_item_category(PlanItem.jg_status)
    render partial: 'get_item_category', locals: { url: "order_kobe_plans_path" }
  end

  # 报送结果列表
  def order_list
    params[:q][:yw_type_eq] = 'jhcg'
    @q = Order.find_all_by_buyer_code(current_user.real_department.id).where(get_conditions("orders")).ransack(params[:q])
    @orders = @q.result.page params[:page]
  end

  # 辖区内采购计划
  def index
    @q = Plan.find_all_by_dep_code(current_user.real_dep_code).where(get_conditions("plans")).ransack(params[:q])
    @plans = @q.result.page params[:page]
  end

  # 新增时 显示项目和品目
  def show_item_category
    @items = get_item_category(PlanItem.xq_status)
    render partial: 'get_item_category', locals: { url: "new_kobe_plan_path" }
  end

  # 某项目采购计划
  # def item_list
  #   params[:q][:user_id_eq] = current_user.id
  #   params[:q][:plan_item_id_eq] = @item.id
  #   @q = Plan.where(get_conditions("plans")).ransack(params[:q])
  #   @plans = @q.result.page params[:page]
  # end

  def new
    @plan.dep_name = current_user.real_department.name
    @plan.dep_man = current_user.name
    @plan.dep_tel = current_user.tel
    @plan.dep_mobile = current_user.mobile
    slave_objs = [@plan.products.build]
    @myform = MasterSlaveForm.new(Plan.xml,PlanProduct.xml(@category),@plan,slave_objs,{form_id: 'new_plan', upload_files: true, title: "<i class='fa fa-pencil-square-o'></i> 新增采购计划--#{@category.name}",action: kobe_plans_path(item_id: @item.id, category_id: @category.id), show_total: true, grid: 3},{title: '产品明细', grid: 3})
  end

  def create
    other_attrs = { plan_item_id: @item.id, category_id: @category.id, category_code: @category.ancestry, department_id: current_user.department.id, dep_code: current_user.real_dep_code }
    create_msform_and_write_logs(Plan, Plan.xml, PlanProduct, PlanProduct.xml(@category), {:action => "录入采购计划", :slave_title => "产品信息"}, other_attrs)
    redirect_to kobe_plans_path
  end

  def update
    update_msform_and_write_logs(@plan, Plan.xml, PlanProduct, PlanProduct.xml(@plan.category), {:action => "修改采购计划", :slave_title => "产品信息"})
    redirect_to kobe_plans_path
  end

  def edit
    slave_objs = @plan.products.blank? ? [@plan.products.build] : @plan.products
    @myform = MasterSlaveForm.new(Plan.xml,PlanProduct.xml(@plan.category),@plan,slave_objs,{form_id: 'new_plan', upload_files: true, title: "<i class='fa fa-wrench'></i> 修改采购计划--#{@plan.category.name}",action: kobe_plan_path(@plan), method: "patch", show_total: true, grid: 3},{title: '产品明细', grid: 3})
  end

  def show
  end

  # 提交
  def commit
    @plan.change_status_and_write_logs("提交", stateless_logs("提交","提交成功！", false), @plan.commit_params)
    # 插入采购计划审核的待办事项
    @plan.reload.create_task_queue
    tips_get("提交成功！")
    redirect_back_or
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_plan_form', action: kobe_plan_path(@plan), method: 'delete' }
  end

  def destroy
    @plan.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_back_or request.referer
  end

  def list
    @plans = audit_list(Plan, params[:tq].to_i == Dictionary.tq_no)
    # arr = []
    # arr << ["plans.status = ? ", 2]
    # arr << ["(task_queues.user_id = ? or task_queues.menu_id in (#{@menu_ids.join(",") }) )", current_user.id]
    # arr << ["task_queues.dep_id = ?", current_user.real_department.id]
    # @q =  Plan.joins(:task_queues).where(get_conditions("plans", arr)).ransack(params[:q])
    # @plans = @q.result(distinct: true).page params[:page]
  end

  def audit

  end

  def update_audit
    save_audit(@plan)
    redirect_to list_kobe_plans_path(tq: Dictionary.tq_no)
  end

  private

    def get_item_category(status=PlanItem.xq_status)
      PlanItem.where(status: status).order("id desc")
    end

    def get_audit_menu_ids
      @menu_ids = Menu.get_menu_ids("Plan|list")
    end

    def get_audit_plan
      @plan = Plan.find_by(id: params[:id]) if params[:id].present?
      audit_tips unless @plan.present? && @plan.cando(action_name,current_user) && can_audit?(@plan,@menu_ids)
    end

    def get_item
      @item = PlanItem.find_by(id: params[:item_id]) if params[:item_id].present?
      cannot_do_tips unless @item.present? && @item.cando("add_plan", current_user)
    end

    def get_category
      @category = Category.find_by(id: params[:category_id]) if params[:category_id].present?
      cannot_do_tips if @category.blank?
    end

    def get_plan
      cannot_do_tips unless @plan.present? && @plan.cando(action_name,current_user)
      audit_tips  if ['audit', 'update_audit'].include?(action_name) && !can_audit?(@plan,@menu_ids)
    end

    def get_show_arr
      obj_contents = show_obj_info(@plan,Plan.xml)
      @plan.products.each_with_index do |p, index|
        obj_contents << show_obj_info(p,PlanProduct.xml(@plan.category),{title: "产品明细 ##{index+1}", grid: 3})
      end
      @arr  = []
      @arr << {title: "详细信息", icon: "fa-info", content: obj_contents}
      @arr << {title: "附件", icon: "fa-paperclip", content: show_uploads(@plan)}
      @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@plan)}
    end

end
