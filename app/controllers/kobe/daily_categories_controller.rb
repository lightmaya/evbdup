# -*- encoding : utf-8 -*-
class Kobe::DailyCategoriesController < KobeController

	skip_before_action :verify_authenticity_token, :only => [:move, :valid_name]
  # protect_from_forgery :except => :index
  before_action :get_daily_category, :only => [:destroy, :delete]
  layout false, :only => [:edit, :new, :show, :delete]

  skip_authorize_resource :only => [:ztree, :valid_name]
  
  def index
  	@daily_category = DailyCategory.find_by(id: params[:id]) if params[:id].present?
  end

  def new
  	@daily_category.parent_id = params[:pid] unless params[:pid].blank?
  	@myform = SingleForm.new(DailyCategory.xml, @daily_category, { form_id: "daily_category_form", action: kobe_daily_categories_path, grid: 3 })
  end

  def edit
  	@myform = SingleForm.new(DailyCategory.xml, @daily_category, { form_id: "daily_category_form", action: kobe_daily_category_path(@daily_category), method: "patch", grid: 3 })
  end

  def show
  	@arr  = []
  	@arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@daily_category,DailyCategory.xml,{grid: 1}) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@daily_category) }
  end

   def create
    daily_category = create_and_write_logs(DailyCategory, DailyCategory.xml)
    if daily_category
      redirect_to kobe_daily_categories_path(id: daily_category)
    else
      render 'index'
    end
  end



  def update
  	if update_and_write_logs(@daily_category, DailyCategory.xml)
  		redirect_to kobe_daily_categories_path(id: @daily_category)
  	else
  		render 'index'
  	end
  end

  # 删除
  def delete
  	render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_daily_category_form', action: kobe_daily_category_path(@daily_category), method: 'delete' }
  end

  def destroy
  	@daily_category.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
  	tips_get("删除成功。")
  	redirect_to kobe_daily_categories_path(id: @daily_category.parent_id)
  end

  def move
  	ztree_move(DailyCategory)
  end

  def ztree
  	ztree_nodes_json(DailyCategory)
  end

  # 验证品目名称
  def valid_name
    params[:obj_id] ||= 0
    render :text => valid_remote(DailyCategory, ["name = ? and id != ?", params[:daily_categories][:name], params[:obj_id]])
  end

  private  

  def get_daily_category
  	cannot_do_tips unless @daily_category.present? && @daily_category.cando(action_name)
  end

end
