# -*- encoding : utf-8 -*-
class Kobe::MenusController < KobeController
  
  skip_before_action :verify_authenticity_token, :only => [:move]
  # protect_from_forgery :except => :index
  before_action :get_menu, :only => [:destroy, :delete]
  layout false, :only => [:edit, :new, :show, :delete]

  skip_authorize_resource :only => [:ztree]
  
	def index
    @menu = Menu.find_by(id: params[:id]) if params[:id].present?
	end

  def new
  	menu = Menu.new
    menu.parent_id = params[:pid] unless params[:pid].blank?
    @myform = SingleForm.new(Menu.xml, menu, { form_id: "menu_form", action: kobe_menus_path, grid: 2 })
  end

  def edit
    @myform = SingleForm.new(Menu.xml, @menu, { form_id: "menu_form", action: kobe_menu_path(@menu), method: "patch", grid: 2 })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@menu,Menu.xml) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@menu) }
  end

  def create
    # other_attrs = {"name" => "我是新名字,会覆盖哦"}
    # menu = create_and_write_logs(Menu, Menu.xml, other_attrs)
    # if menu
    #   menu.XXXX
    #   tips_get("操作成功。")
    #   redirect_to kobe_menus_path
    # else
    #   flash_get(menu.errors.full_messages)
    #   render 'index'
    # end
    menu = create_and_write_logs(Menu, Menu.xml)
    if menu
      redirect_to kobe_menus_path(id: menu)
    else
      render 'index'
    end
  end

  def update
    if update_and_write_logs(@menu, Menu.xml)
      redirect_to kobe_menus_path(id: @menu)
    else
      render 'index'
    end
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_menu_form', action: kobe_menu_path(@menu), method: 'delete' }
  end

  def destroy
    @menu.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_menus_path(id: @menu.parent_id)
  end

  def move
    ztree_move(Menu)
  end

  def ztree
    ztree_nodes_json(Menu)
  end

  private  

    def get_menu
      cannot_do_tips unless @menu.present? && @menu.cando(action_name)
    end

end
