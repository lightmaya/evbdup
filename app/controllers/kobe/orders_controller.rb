# -*- encoding : utf-8 -*-
class Kobe::OrdersController < KobeController

  before_action :get_obj, :only => [:show, :edit, :update, :destroy, :commit, :print]
  before_action :get_audit_obj, :only => [:audit, :update_audit]
  before_action :get_show_arr, :only => [:audit, :show]
  before_action :check_same_template, :only => [:create, :update]
  skip_before_action :verify_authenticity_token, :only => [:same_template, :commit]

  skip_authorize_resource :only => [:same_template]

  # 辖区内采购项目
  def index
    @q = Order.find_all_by_buyer_code(current_user.department.real_ancestry).where(get_conditions("orders")).ransack(params[:q]) 
    @objs = @q.result.page params[:page]
  end

  def new
  	obj = Order.new
    obj.yw_type = 'ddcg'
  	obj.buyer_name = obj.payer = current_user.department.real_dep.name
    obj.buyer_man = current_user.name
    obj.buyer_tel = current_user.tel
    obj.buyer_mobile = current_user.mobile
    obj.buyer_addr = current_user.department.address
    slave_objs = [OrdersItem.new(order_id: obj.id)]
    @ms_form = MasterSlaveForm.new(Order.xml,OrdersItem.xml,obj,slave_objs,{form_id: 'new_order', upload_files: true, min_number_of_files: 1, title: '<i class="fa fa-pencil-square-o"></i> 下单',action: kobe_orders_path, show_total: true, grid: 4},{title: '产品明细', grid: 4})
  end

  def show
  end

  def create
    other_attrs = { buyer_id: current_user.department.id, buyer_code: current_user.department.real_ancestry, user_id: current_user.id, name: get_project_name }
    obj = create_msform_and_write_logs(Order, Order.xml, OrdersItem, OrdersItem.xml, {:action => "下单", :master_title => "基本信息",:slave_title => "产品信息"}, other_attrs)
    unless obj.id
      redirect_back_or
    else
      redirect_to eval("#{@obj.yw_type}_list_kobe_orders_path")
    end
  end

  def update
    update_msform_and_write_logs(@obj, Order.xml, OrdersItem, OrdersItem.xml, {:action => "修改订单", :master_title => "基本信息",:slave_title => "产品信息"}, { name: get_project_name(@obj) })
    redirect_to eval("#{@obj.yw_type}_list_kobe_orders_path")
  end

  def edit
    slave_objs = @obj.items.blank? ? [OrdersItem.new(order_id: @obj.id)] : @obj.items
    @ms_form = MasterSlaveForm.new(Order.xml,OrdersItem.xml,@obj,slave_objs,{form_id: 'new_order', upload_files: true, title: '<i class="fa fa-wrench"></i> 修改订单',action: kobe_order_path(@obj), method: "patch", show_total: true, grid: 4},{title: '产品明细', grid: 4})
  end

  # 提交
  def commit
    remark = @obj.find_step_by_rule.blank? ? "提交成功！项目已生效。" : "提交成功！请等待#{@obj.find_step_by_rule["name"]}。"
    logs = stateless_logs("提交",remark, false)
    @obj.change_status_and_write_logs("提交",logs,@obj.commit_params, false)
    @obj.reload.create_task_queue
    tips_get(remark)
    redirect_to eval("#{@obj.yw_type}_list_kobe_orders_path")
  end

  # 审核定点采购项目
  def audit_ddcg
    arr = []
    arr << ["orders.yw_type = ? ", 'ddcg']
    audit_list(arr)
  end
  

  # 我的定点采购项目
  def ddcg_list
    arr = []
    arr << ["orders.user_id = ?", current_user.id]
    arr << ["orders.yw_type = ?", 'ddcg']
    @q = Order.where(get_conditions("orders", arr)).ransack(params[:q]) 
    @objs = @q.result.page params[:page]
  end

  def audit
  end

  def update_audit
    save_audit(@obj)
    redirect_to eval("audit_#{@obj.yw_type}_kobe_orders_path")
  end

  # 根据category_id判断模版是否相同
  def same_template
    templates = get_templates(params[:category_ids].split(","))
    render :text => templates.size
  end

  def print
    render partial: @obj.ht
  end

  private

    def get_obj
      if params[:id].present?
        # if can? :admin, Order
        #   @obj = Order.find_by(id: params[:id]) 
        # else
          if current_user.is_admin
            @obj = Order.find_all_by_buyer_code(current_user.department.real_ancestry).find_by(id: params[:id]) 
          else
            @obj = current_user.orders.find_by(id: params[:id]) 
          end
        # end
      end
      cannot_do_tips unless @obj.present? && @obj.cando(action_name,current_user)
    end

    # 审核时获取obj
    def get_audit_obj
      if params[:id].present?
        @obj = Order.find_by(id: params[:id])
      end
      menu_ids = Menu.get_menu_ids("Order|audit_#{@obj.yw_type}") if @obj.present?
      audit_tips unless @obj.present? && @obj.cando(action_name,current_user) && can_audit?(@obj,menu_ids)
    end

    # 根据品目创建项目名称
    def get_project_name(obj=nil)
      category_names = params[:orders_items][:category_name].values.join("、")
      if obj.present?
        project_name = obj.name.split(" ")
        project_name[2] = category_names
        return project_name.join(" ")
      else
        return "#{current_user.department.real_dep.name} #{Time.new.to_date.to_s} #{category_names} 定点采购项目"
      end
    end

    # show页面的数组
    def get_show_arr
      obj_contents = show_obj_info(@obj,Order.xml,{title: "基本信息"})
      @obj.items.each_with_index do |item, index|
        obj_contents << show_obj_info(item,OrdersItem.xml,{title: "产品明细 ##{index+1}"})
      end
      @arr  = []
      @arr << {title: "详细信息", icon: "fa-info", content: obj_contents}
      @arr << {title: "附件", icon: "fa-paperclip", content: show_uploads(@obj)}
      @arr << {title: "评价", icon: "fa-star-half-o", content: show_estimates(@obj)}
      @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@obj)}
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
      arr << ["task_queues.dep_id = ?", current_user.department.real_dep.id]
      @q =  Order.joins(:task_queues).where(get_conditions("orders", arr)).ransack(params[:q])
      @objs = @q.result(distinct: true).page params[:page]
    end
end
