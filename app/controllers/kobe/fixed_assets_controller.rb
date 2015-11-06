class Kobe::FixedAssetsController < KobeController
  # protect_from_forgery :except => :index
  before_action :get_category, :only => [:new, :create]


   
	def index
		@q = FixedAsset.ransack(params[:q]) 
    @fixed_assets = @q.result.status_not_in(404).page params[:page]
	end

  def new 
    @fixed_asset.dep_name = current_user.department.name
    @myform = SingleForm.new(FixedAsset.xml, @fixed_asset, { form_id: "asset_form", title: "<i class='fa fa-pencil-square-o'></i> 新增车辆费用", action: kobe_fixed_assets_path(category_id: @category.id ), grid: 3 })
  end

  def edit
    @myform = SingleForm.new(FixedAsset.xml, @fixed_asset, { form_id: "asset_form", action: kobe_fixed_asset_path(@fixed_asset), method: "patch", grid: 3 })
  end

  def show
    @arr  = []
    obj_contents = show_obj_info(@fixed_asset,FixedAsset.xml,{title: "基本信息" , grid: 3})
    @arr << { title: "详细信息", icon: "fa-info", content: obj_contents }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@fixed_asset)}
  end

  def create
  	create_and_write_logs(FixedAsset, FixedAsset.xml, {} , { category_id: @category.id, category_code: @category.ancestry, category_name: @category.name, department_id: current_user.department.id})
    redirect_to kobe_fixed_assets_path
  end

  def update
    update_and_write_logs(@fixed_asset, FixedAsset.xml)
    redirect_to kobe_fixed_assets_path
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_fixed_asset_form', action: kobe_fixed_asset_path(@fixed_asset), method: 'delete' }
  end

  def destroy
    @fixed_asset.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_fixed_assets_path
  end

 private

   def get_category
      @category = Category.find_by(id: params[:category_id]) if params[:category_id].present?
      cannot_do_tips if @category.blank?
   end

end
