# -*- encoding : utf-8 -*-
class Kobe::BidProjectsController < KobeController
  skip_before_action :verify_authenticity_token, :only => [:commit]
  before_action :get_audit_menu_ids, :only => [:list, :audit, :update_audit]
  before_filter :check_bid_project, only: [:choose, :pre_choose]

  def index
    params[:q][:user_id_eq] = current_user.id unless current_user.admin?
    @q = BidProject.where(get_conditions("bid_projects")).ransack(params[:q]) 
    @bid_projects = @q.result.includes([:bid_project_bids]).page params[:page]
  end

  def show
    obj_contents = show_obj_info(@bid_project, BidProject.xml, {title: "基本信息", grid: 3}) 
    @arr  = []
    @bid_project.items.each_with_index do |item, index|
      obj_contents << show_obj_info(item, BidItem.xml, {title: "产品明细 ##{index+1}", grid: 4})
    end
    @arr << { title: "详细信息", icon: "fa-info", content: obj_contents }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@bid_project) }
  end

  def bid
  end

  def audit
  end

  def pre_choose
    @obj_contents = show_obj_info(@bid_project, BidProject.xml, {title: "基本信息", grid: 3}) 
    @bid_project.items.each_with_index do |item, index|
      @obj_contents << show_obj_info(item, BidItem.xml, {title: "产品明细 ##{index+1}", grid: 4})
    end
    @bpbs = @bid_project.bid_project_bids.order("bid_project_bids.total ASC")
    # 默认第一中标人
    @bid_project.bid_project_bid_id = @bpbs.first.id
  end

  def choose
    other_attrs = {status: 12}
    update_and_write_logs(@bid_project, BidProject.xml, other_attrs)
    redirect_to action: :index
    # @bid_project.update(params[:bid_project].permit(:bid_project_bid_id, :reason))
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
    arr << ["task_queues.dep_id = ?", current_user.real_department.id]
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
    @bid_project.buyer_dep_name = current_user.department.name
    @bid_project.buyer_name = current_user.name
    @bid_project.buyer_phone = current_user.tel
    @bid_project.buyer_mobile = current_user.mobile
    @bid_project.buyer_email = current_user.email
    @bid_project.buyer_add = current_user.department.address

    slave_objs = [@bid_project.items.build]
    @ms_form = MasterSlaveForm.new(BidProject.xml, BidItem.xml, @bid_project, slave_objs,
      { form_id: "bid_project_form", action: kobe_bid_projects_path, upload_files: true, 
        upload_files_name: "bid_project", 
        title: '<i class="fa fa-pencil-square-o"></i> 新增竞价', grid: 4},
        {title: '产品明细', grid: 4}
      )
  end

  def edit
    slave_objs = @bid_project.items.blank? ? [@bid_project.items.build] : @bid_project.items
    @ms_form = MasterSlaveForm.new(BidProject.xml, BidItem.xml, @bid_project,slave_objs,{upload_files: true, min_number_of_files: 1, title: '<i class="fa fa-wrench"></i> 修改竞价',action: kobe_bid_project_path(@order), method: "patch", show_total: true, grid: 4},{title: '产品明细', grid: 4})
  end

  def create
    other_attrs = {buyer_dep_name: current_user.department.name, department_id: current_user.department.id, department_code: current_user.department.real_ancestry, name: get_project_name }
    obj = create_msform_and_write_logs(BidProject, BidProject.xml, BidItem, BidItem.xml, { :master_title => "基本信息",:slave_title => "产品信息"}, other_attrs)
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

    def get_project_name
      category_names = params[:bid_items][:category_name].values.uniq.join("、")
      "#{params[:bid_projects][:buyer_dep_name]}#{category_names}竞价项目"
    end

    # 只允许自己操作自己的项目
    def check_bid_project
      @bid_project = current_user.admin? ? BidProject.find_by_id(params[:id]) : current_user.bid_projects.find_by_id(params[:id])
      return redirect_to not_fount_path unless @bid_project
    end
end
