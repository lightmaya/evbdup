# -*- encoding : utf-8 -*-
class Kobe::DailyCostsController < KobeController
  before_action :get_show_arr, :only => [:audit, :show]
  before_action :get_audit_menu_ids, :only => [:list, :audit, :update_audit]
  before_action :get_daily_cost, :except => [:index, :new, :create, :list]
  skip_before_action :verify_authenticity_token, :only => [:commit]

  # 辖区内采购计划
  def index
    @q = DailyCost.where(get_conditions("daily_costs")).ransack(params[:q]) 
    @daily_costs = @q.result.page params[:page]
  end

  def new
    @daily_cost.dep_name = current_user.department.name
    @daily_cost.dep_man = current_user.name
    slave_objs = [@daily_cost.items.build]
    @myform = MasterSlaveForm.new(DailyCost.xml,DailyCostItem.xml,@daily_cost,slave_objs,{form_id: 'new_daily_cost', title: "<i class='fa fa-pencil-square-o'></i> 新增日常费用",action: kobe_daily_costs_path, show_total: true, grid: 3},{title: '费用明细', grid: 3})
  end

  def create
    other_attrs = { name: create_name , department_id: current_user.department.id, dep_code: current_user.real_dep_code }
    create_msform_and_write_logs(DailyCost, DailyCost.xml, DailyCostItem, DailyCostItem.xml, {:action => "录入费用信息", :slave_title => "费用明细"}, other_attrs)
    redirect_to  kobe_daily_costs_path
  end

  def update
    update_msform_and_write_logs(@daily_cost, DailyCost.xml, DailyCostItem, DailyCostItem.xml, {:action => "修改费用信息", :slave_title => "费用信息"}, {name: create_name})
    redirect_to kobe_daily_costs_path 
  end

  def edit
    slave_objs = @daily_cost.items.blank? ? [@daily_cost.items.build] : @daily_cost.items
    @myform = MasterSlaveForm.new(DailyCost.xml,DailyCostItem.xml , @daily_cost, slave_objs,{form_id: 'new_daily_cost', title: "<i class='fa fa-wrench'></i> 修改日常费用" , action: kobe_daily_cost_path(@daily_cost), method: "patch", show_total: true, grid: 3},{title: '费用明细', grid: 3})
  end

  def show
  end

  # 提交
  def commit
    @daily_cost.change_status_and_write_logs("提交",stateless_logs("提交","提交成功！", false),@daily_cost.commit_params)
    # 插入日常费用审核的待办事项
    @daily_cost.reload.create_task_queue
    tips_get("提交成功！")
    redirect_back_or
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_daily_cost_form', action: kobe_daily_cost_path(@daily_cost), method: 'delete' }
  end

  def destroy
    @daily_cost.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_back_or request.referer
  end

  def list
    arr = []
    arr << ["daily_costs.status = ? ", 2]
    arr << ["(task_queues.user_id = ? or task_queues.menu_id in (#{@menu_ids.join(",") }) )", current_user.id]
    arr << ["task_queues.dep_id = ?", current_user.real_department.id]
    @q =  DailyCost.joins(:task_queues).where(get_conditions("daily_costs", arr)).ransack(params[:q])
    @daily_costs = @q.result(distinct: true).page params[:page]
  end

  def audit

  end

  def update_audit
    save_audit(@daily_cost)
    redirect_to list_kobe_daily_costs_path
  end


  private

    def get_audit_menu_ids
      @menu_ids = Menu.get_menu_ids("DailyCost|list")
    end

   #是否有权限操作项目
    def get_daily_cost
      cannot_do_tips unless @daily_cost.present? && @daily_cost.cando(action_name,current_user)
      audit_tips  if ['audit', 'update_audit'].include?(action_name) && !can_audit?(@daily_cost,@menu_ids)
    end
   
    def get_show_arr
      obj_contents = show_obj_info(@daily_cost,DailyCost.xml,{grid: 3})
      @daily_cost.items.each_with_index do |p, index|
        obj_contents << show_obj_info(p,DailyCostItem.xml,{title: "产品明细 ##{index+1}", grid: 3})
      end
      @arr  = []
      @arr << {title: "详细信息", icon: "fa-info", content: obj_contents}
      @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@daily_cost)}
    end

    def create_name
      "#{params[:daily_costs][:deliver_at]} #{params[:daily_cost_items][:category_name].values.uniq.join(',')}"
    end

end
