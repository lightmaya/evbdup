# -*- encoding : utf-8 -*-
class Kobe::MenusController < KobeController
  # load_and_authorize_resource
  
  skip_before_action :verify_authenticity_token, :only => [:move,:destroy]
  # protect_from_forgery :except => :index
  before_action :get_menu, :only => [:edit, :update, :destroy, :show]
  before_action :get_icon, :only => [:new, :index, :edit, :show]
  layout false, :only => [:edit, :new, :show]

	def index
		@menu = Menu.new
	end

  def new
  	@menu = Menu.new
    @menu.parent_id = params[:pid] unless params[:pid].blank?
  end

  def edit

  end

  def show
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

    if create_and_write_logs(Menu, Menu.xml)
      redirect_to kobe_menus_path
    else
      render 'index'
    end
  end

  def update
    if update_and_write_logs(@menu, Menu.xml)
      redirect_to kobe_menus_path
    else
      render 'index'
    end
  end

  def destroy
    if @menu.destroy
      render :text => "删除成功！"
    else
      render :text => "操作失败！"
    end
  end

  def move
    ztree_move(Menu)
  end

  def ztree
    ztree_json(Menu)
  end

  private  

    def get_menu
      @menu = Menu.find(params[:id]) unless params[:id].blank?
    end

    def get_icon
      @icon = Icon.leaves.map(&:name)
    end

end
