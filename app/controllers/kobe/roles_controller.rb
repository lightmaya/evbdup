# -*- encoding : utf-8 -*-
class Kobe::RolesController < KobeController
  # load_and_authorize_resource
  
  skip_before_action :verify_authenticity_token, :only => [:move]
  # protect_from_forgery :except => :index
  before_action :get_role, :only => [:edit, :update, :destroy, :show, :index, :delete]
  layout false, :only => [:edit, :new, :show, :delete]

	def index
	end

  def new
  	role = Role.new
    role.parent_id = params[:pid] unless params[:pid].blank?
    @myform = SingleForm.new(Role.xml, role, { form_id: "role_form", action: kobe_role_path(role), grid: 2 })
  end

  def edit
    @myform = SingleForm.new(Role.xml, @role, { form_id: "role_form", action: kobe_role_path(@role), method: "patch", grid: 2 })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@role,Role.xml) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@role) }
  end

  def create
    role = create_and_write_logs(Role, Role.xml)
    if role
      role.menu_ids = role.menuids.split(",")
      redirect_to kobe_roles_path(id: role)
    else
      render 'index'
    end
  end

  def update
    if update_and_write_logs(@role, Role.xml)
      @role.menu_ids = @role.menuids.split(",")
      redirect_to kobe_roles_path(id: @role)
    else
      render 'index'
    end
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_role_form', action: kobe_role_path(@role), method: 'delete' }
  end

  def destroy
    if @role.change_status_and_write_logs("已删除", stateless_logs("删除",params[:opt_liyou]))
      tips_get("删除单位成功。")
    else
      flash_get(@role.errors.full_messages)
    end
    redirect_to kobe_roles_path(id: @role.parent_id)
  end

  def move
    ztree_move(Role)
  end

  def ztree
    ztree_json(Role)
  end

  private  

    def get_role
      @role = Role.find_by_id(params[:id]) unless params[:id].blank?
    end

end
