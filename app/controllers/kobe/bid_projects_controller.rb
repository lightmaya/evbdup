# -*- encoding : utf-8 -*-
class Kobe::BidProjectsController < KobeController
  skip_before_action :verify_authenticity_token, :only => [:commit]
  before_action :get_audit_menu_ids, :only => [:list, :audit, :update_audit]

  def index
    params[:q][:user_id_eq] = current_user.id unless current_user.admin?
    @q = BidProject.where(get_conditions("bid_projects")).ransack(params[:q]) 
    @bid_projects = @q.result.page params[:page]
  end

  def show
  end

  def audit

  end

  def update_audit
    save_audit(@bid_project)
    # 给刚注册的审核通过的入围供应商插入待办事项
    redirect_to list_kobe_bid_projects_path
  end

  def list
    arr = []
    arr << ["bid_projects.status = ? ", 1]
    arr << ["(task_queues.user_id = ? or task_queues.menu_id in (#{@menu_ids.join(",") }) )", current_user.id]
    arr << ["task_queues.dep_id = ?", current_user.department.real_dep.id]
    cdt = get_conditions("bid_projects", arr)
    @q =  BidProject.joins(:task_queues).where(cdt).ransack(params[:q]) 
    @bid_projects = @q.result(distinct: true).page params[:page]
  end

  # 获取审核的menu_ids
  def get_audit_menu_ids
    @menu_ids = Menu.get_menu_ids("BidProject|list")
  end

  # 注册提交
  def commit
    @bid_project.change_status_and_write_logs("提交审核",
      stateless_logs("提交审核","注册完成，提交审核！", false),
      @bid_project.commit_params, false)
    @bid_project.reload.create_task_queue
    tips_get("提交成功，请等待审核。")
    redirect_to kobe_bid_projects_path(id: @bid_project)
  end

  def new
    @bid_project.top_dep_name = current_user.department.root.name
    @bid_project.buyer_dep_name = current_user.department.name
    @bid_project.buyer_name = current_user.name
    @bid_project.buyer_phone = current_user.tel
    @bid_project.buyer_mobile = current_user.mobile
    @bid_project.buyer_email = current_user.email

    slave_objs = [@bid_project.items.build]
    @ms_form = MasterSlaveForm.new(BidProject.xml, BidItem.xml, @bid_project, slave_objs,
      { form_id: "bid_project_form", action: kobe_bid_projects_path, upload_files: true, 
        upload_files_name: "bid_project", 
        title: '<i class="fa fa-pencil-square-o"></i> 新增公告', grid: 4},
        {title: '产品明细', grid: 4}
      )
  end

  def edit
    @myform = SingleForm.new(BidProject.xml, @bid_project, { form_id: "bid_project_form", action: kobe_bid_project_path(@bid_project), method: "patch", grid: 2 })
  end

  def create
    obj = create_msform_and_write_logs(BidProject, BidProject.xml, BidItem, BidItem.xml, { :master_title => "基本信息",:slave_title => "产品信息"})
    redirect_to kobe_bid_projects_path
  end

  def update
    update_and_write_logs(@bid_project, BidProject.xml)
    redirect_to kobe_bid_projects_path
  end

  # 批处理
  def batch_task
    render :text => params[:grid].to_s
  end

    # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_bid_project_form', action: kobe_bid_project_path(@bid_project), method: 'delete' }
  end

  def destroy
    @bid_project.change_status_and_write_logs("已删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_bid_projects_path
  end

  private  

    # 只允许传递过来的参数
    def my_params  
      params.require(:bid_projects).permit(:title, :new_days, :top_type, 
        :access_permission, :content)  
    end
end