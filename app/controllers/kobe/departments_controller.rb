# -*- encoding : utf-8 -*-
class Kobe::DepartmentsController < KobeController

  skip_before_action :verify_authenticity_token, :only => [:move, :valid_dep_name, :commit]
  before_action :get_dep, :only => [:index, :show, :edit, :update, :add_user, :delete, :destroy, :freeze, :update_freeze, :recover, :update_recover, :upload, :update_upload, :commit]
  layout :false, :only => [:show, :edit, :new, :add_user, :delete, :freeze, :recover, :upload, :commit]

  def index
    @dep ||= current_user.department
  end

  def move
    ztree_move(Department)
  end

  def ztree
    ztree_nodes_json(Department,current_user.department)
  end

  def new
    dep = Department.new
    dep.parent_id = params[:pid] unless params[:pid].blank?
    @myform = SingleForm.new(dep.parent.get_xml, dep, { form_id: "department_form", action: kobe_department_path(dep), grid: 2 })
  end

  def create
    p_id = params[:departments][:parent_id].present? ? params[:departments][:parent_id] : 2
    parent_dep = Department.find_by_id(p_id) 
    dep = create_and_write_logs(Department, parent_dep.get_xml)
    if dep
      redirect_to kobe_departments_path(id: dep)
    else
      redirect_to root_path
    end
  end

  def update
    if update_and_write_logs(@dep, @dep.get_xml)
      redirect_to kobe_departments_path(id: @dep)
    else
      redirect_back_or
    end
  end

  def edit
    @myform = SingleForm.new(@dep.get_xml, @dep, { form_id: "department_form", action: kobe_department_path(@dep), method: "patch", grid: 2 })
  end

  def show
    @arr  = []
    @arr << { title: "附件", icon: "fa-paperclip", content: show_uploads(@dep,true) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@dep) }
  end

  # 删除单位
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_dep_form', action: kobe_department_path(@dep), method: 'delete' }
  end
  
  def destroy
    if @dep.change_status_and_write_logs("已删除", stateless_logs("删除",params[:opt_liyou]))
      tips_get("删除单位成功。")
    else
      flash_get(@dep.errors.full_messages)
    end
    redirect_to kobe_departments_path(id: @dep.parent_id)
  end

  # 冻结单位
  def freeze
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'freeze_dep_form', action: update_freeze_kobe_department_path(@dep) }
  end

  def update_freeze
    if @dep.change_status_and_write_logs("冻结", stateless_logs("冻结",params[:opt_liyou]))
      tips_get("冻结单位成功。")
    else
      flash_get(@dep.errors.full_messages)
    end
    redirect_to kobe_departments_path(id: @dep)
  end

  # 恢复单位
  def recover
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'recover_dep_form', action: update_recover_kobe_department_path(@dep) }
  end

  def update_recover
    if @dep.change_status_and_write_logs("正常", stateless_logs("恢复",params[:opt_liyou]))
      tips_get("恢复单位成功。")
    else
      flash_get(@dep.errors.full_messages)
    end
    redirect_to kobe_departments_path(id: @dep)
  end

  # 分配人员账号
  def add_user
  end

  def update_add_user
    attributes = params.require(:user).permit(:login, :password, :password_confirmation)
    attributes[:department_id] = params[:id]
    user = User.new(attributes)
    if user.save
      write_logs(user,"分配人员账号",'账号创建成功')
      tips_get("账号创建成功。")
      redirect_to kobe_departments_path(id: params[:id],u_id: user.id)
    else
      flash_get(user.errors.full_messages)
      redirect_back_or
    end
  end

  # 修改资质证书
  def upload
    @myform = SingleForm.new(nil, @dep, { form_id: "edit_upload", button: false, upload_files: true, min_number_of_files: 4, action: update_upload_kobe_department_path(@dep) })
  end

  def update_upload
    tips_get("上传资质证书成功。")
    redirect_to kobe_departments_path(id: @dep)
  end

  # 注册提交
  def commit
    if @dep.change_status_and_write_logs("等待审核",stateless_logs("提交","注册完成，提交！", false))
      tips_get("提交成功，请等待审核。")
    else
      flash_get(@dep.errors.full_messages)
    end
    redirect_to kobe_departments_path(id: @dep)
  end

  # 验证单位名称
  def valid_dep_name
    render :text => valid_remote(Department, ["name = ? and id <> ? and dep_type is false and status <> 404", params[:departments][:name], params[:obj_id]])
  end

  private  

    def get_dep
      @dep = Department.find_by_id(params[:id]) unless params[:id].blank? 
    end
end
