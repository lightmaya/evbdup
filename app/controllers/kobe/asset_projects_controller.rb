# -*- encoding : utf-8 -*-
class Kobe::AssetProjectsController < KobeController
  before_action :get_show_arr, :only => [:audit, :show]
  before_action :get_audit_menu_ids, :only => [:list, :audit, :update_audit,:get_fixed_asset_json]
  before_action :get_asset_project, :except => [:index, :new, :create, :list,:get_fixed_asset_json]
  skip_before_action :verify_authenticity_token, :only => [:commit,:get_fixed_asset_json]
  skip_load_and_authorize_resource :only => :get_fixed_asset_json

  # 辖区内采购计划
  def index
    @q = AssetProject.where(get_conditions("asset_projects")).ransack(params[:q])
    @asset_projects = @q.result.page params[:page]
  end

  def new
    @asset_project.dep_name = current_user.real_department.name
    @asset_project.dep_man = current_user.name
    slave_objs = [@asset_project.items.build]
    @myform = MasterSlaveForm.new(AssetProject.xml,AssetProjectItem.xml,@asset_project,slave_objs,{form_id: 'new_asset_project', title: "<i class='fa fa-pencil-square-o'></i> 新增车辆费用报销", action: kobe_asset_projects_path, show_total: true, grid: 3},{title: '费用明细', grid: 3})
  end

  def create
    other_attrs = { department_id: current_user.department.id, dep_code: current_user.real_dep_code }
    create_msform_and_write_logs(AssetProject, AssetProject.xml, AssetProjectItem, AssetProjectItem.xml, {:action => "录入费用信息", :slave_title => "费用明细"}, other_attrs)
    redirect_to  kobe_asset_projects_path
  end

  def update
    update_msform_and_write_logs(@asset_project, AssetProject.xml, AssetProjectItem, AssetProjectItem.xml, {:action => "修改费用信息", :slave_title => "费用信息"})
    redirect_to kobe_asset_projects_path
  end

  def edit
    slave_objs = @asset_project.items.blank? ? [@asset_project.items.build] : @asset_project.items
    @myform = MasterSlaveForm.new(AssetProject.xml,AssetProjectItem.xml , @asset_project, slave_objs,{form_id: 'new_asset_project', title: "<i class='fa fa-wrench'></i> 修改车辆费用报销" , action: kobe_asset_project_path(@asset_project), method: "patch", show_total: true, grid: 3},{title: '费用明细', grid: 3})
  end

  def show
  end

  # 提交
  def commit
    @asset_project.change_status_and_write_logs("提交",stateless_logs("提交","提交成功！", false),@asset_project.commit_params)
    # 插入车辆费用报销审核的待办事项
    @asset_project.reload.create_task_queue
    tips_get("提交成功！")
    redirect_back_or
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_asset_project_form', action: kobe_asset_project_path(@asset_project), method: 'delete' }
  end

  def destroy
    @asset_project.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_back_or request.referer
  end

  def list
    @asset_projects = audit_list(AssetProject)
    # arr = []
    # arr << ["asset_projects.status = ? ", AssetProject.audit_status]
    # arr << ["(task_queues.user_id = ? or task_queues.menu_id in (#{@menu_ids.join(",") }) )", current_user.id]
    # arr << ["task_queues.dep_id = ?", current_user.real_department.id]
    # @q =  AssetProject.joins(:task_queues).where(get_conditions("asset_projects", arr)).ransack(params[:q])
    # @asset_projects = @q.result(distinct: true).page params[:page]
  end

  def audit

  end

  def update_audit
    save_audit(@asset_project)
    redirect_to list_kobe_asset_projects_path
  end
  def get_fixed_asset_json
    nodes = FixedAsset.select("id,name").where(['status=? and asset_status=?',0,1]).to_json
    render :json=>nodes
  end


  private

    def get_audit_menu_ids
      @menu_ids = Menu.get_menu_ids("AssetProject|list")
    end

    #是否有权限操作项目
    def get_asset_project
      cannot_do_tips unless @asset_project.present? && @asset_project.cando(action_name,current_user)
      audit_tips  if ['audit', 'update_audit'].include?(action_name) && !can_audit?(@asset_project,@menu_ids)
    end
    def get_show_arr
      obj_contents = show_obj_info(@asset_project,AssetProject.xml,{grid: 3})
      @asset_project.items.each_with_index do |p, index|
        obj_contents << show_obj_info(p,AssetProjectItem.xml,{title: "产品明细 ##{index+1}", grid: 3})
      end
      @arr  = []
      @arr << {title: "详细信息", icon: "fa-info", content: obj_contents}
      @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@asset_project)}
    end

end
