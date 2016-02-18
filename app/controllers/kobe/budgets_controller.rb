# -*- encoding : utf-8 -*-
class Kobe::BudgetsController < KobeController

  before_action :get_show_arr, :only => [:audit, :show]
  before_action :get_audit_menu_ids, :only => [:list, :audit, :update_audit]
  before_action :get_budget, :except => [:index, :new, :create, :list]
  skip_before_action :verify_authenticity_token, :only => [:commit]

  # 我的预算审批单
  def index
    @q = Budget.find_all_by_dep_code(current_user.real_dep_code).where(get_conditions("budgets")).ransack(params[:q])
    @budgets = @q.result.page params[:page]
  end

  def new
    @myform = SingleForm.new(Budget.xml, @budget, { form_id: "budget_form", upload_files: true, min_number_of_files: 1, action: kobe_budgets_path, title: "<i class='fa fa-pencil-square-o'></i> 新增预算审批单", grid: 2 })
  end

  def create
    create_and_write_logs(Budget, Budget.xml, {}, { department_id: current_user.department.id, dep_code: current_user.real_dep_code })
    redirect_to kobe_budgets_path
  end

  def update
    update_and_write_logs(@budget, Budget.xml)
    redirect_to kobe_budgets_path
  end

  def edit
    @myform = SingleForm.new(Budget.xml, @budget, { form_id: "budget_form", upload_files: true, min_number_of_files: 1, action: kobe_budget_path(@budget), method: "patch", title: "<i class='fa fa-pencil-square-o'></i> 修改预算审批单", grid: 2 })
  end

  def show
  end

  # 提交
  def commit
    @budget.change_status_and_write_logs("提交",stateless_logs("提交","提交成功！", false),@budget.commit_params)
    # 插入预算审批单审核的待办事项
    @budget.reload.create_task_queue
    tips_get("提交成功！")
    redirect_back_or
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_budget_form', action: kobe_budget_path(@budget), method: 'delete' }
  end

  def destroy
    @budget.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_back_or request.referer
  end

  def list
    @budgets = audit_list(Budget)
    # arr = []
    # arr << ["budgets.status = ? ", 1]
    # arr << ["(task_queues.user_id = ? or task_queues.menu_id in (#{@menu_ids.join(",") }) )", current_user.id]
    # arr << ["task_queues.dep_id = ?", current_user.real_department.id]
    # @q =  Budget.joins(:task_queues).where(get_conditions("budgets", arr)).ransack(params[:q])
    # @budgets = @q.result(distinct: true).page params[:page]
  end

  def audit

  end

  def update_audit
    save_audit(@budget)
    redirect_to list_kobe_budgets_path
  end

  private

    def get_audit_menu_ids
      @menu_ids = Menu.get_menu_ids("Budget|list")
    end

    def get_budget
      cannot_do_tips unless @budget.present? && @budget.cando(action_name,current_user)
      audit_tips  if ['audit', 'update_audit'].include?(action_name) && !can_audit?(@budget,@menu_ids)
    end

    def get_show_arr
      @arr  = []
      @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@budget,Budget.xml) }
      @arr << { title: "附件", icon: "fa-paperclip", content: show_uploads(@budget, { is_picture: true }) }
      @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@budget) }
    end

end
