# -*- encoding : utf-8 -*-
class Kobe::CategoriesController < KobeController

  skip_before_action :verify_authenticity_token, :only => [:move, :valid_name]
  # protect_from_forgery :except => :index
  before_action :get_category, :only => [:delete, :destroy, :freeze, :update_freeze, :recover, :update_recover]
  layout false, :only => [:edit, :new, :show, :delete, :freeze, :recover]

  skip_authorize_resource :only => [:ztree, :valid_name]

  def index
    @category = Category.find(params[:id]) if params[:id].present?
  end

  def show
    @arr  = []
    obj_contents = show_obj_info(@category, Category.xml)
    if @category.is_childless?
      create_objs_from_xml_model(@category.params_xml, CategoryParam).each_with_index do |param,index|
        obj_contents << show_obj_info(param,CategoryParam.xml,{title: "参数明细 ##{index+1}"})
      end
    end
    @arr << {title: "详细信息", icon: "fa-info", content: obj_contents}
    @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@category)}
  end

  def new
    @category.parent_id = params[:pid] if params[:pid].present?
    slave_objs = create_objs_from_xml_model(CategoryParam.default_xml, CategoryParam)
    @ms_form = MasterSlaveForm.new(Category.xml, CategoryParam.xml, @category, slave_objs, { form_id: 'new_category', title: '<i class="fa fa-pencil-square-o"></i> 新增品目', action: kobe_categories_path, grid: 2 }, { title: '参数明细', grid: 4 })
  end

  def edit
    sobj = Nokogiri::XML(@category.params_xml).xpath("/root/node").present? ? @category.params_xml : CategoryParam.default_xml
    slave_objs = create_objs_from_xml_model(sobj, CategoryParam)
    @ms_form = MasterSlaveForm.new(Category.xml, CategoryParam.xml, @category, slave_objs, { action: kobe_category_path(@category), method: "patch", grid: 2 }, { title: '参数明细', grid: 4 })
  end

  def create
    category = create_and_write_logs(Category, Category.xml, { :action => "新增品目" }, { "params_xml" => create_xml(CategoryParam.xml, CategoryParam) })
    if category
      redirect_to kobe_categories_path(id: category)
    else
      redirect_back_or
    end
  end

  def update
    update_and_write_logs(@category, Category.xml, { :action => "修改品目" }, { "params_xml" => create_xml(CategoryParam.xml, CategoryParam) })
    redirect_to kobe_categories_path(id: @category)
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_category_form', action: kobe_category_path(@category), method: 'delete' }
  end

  def destroy
    @category.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    @category.clean_cache_ids
    tips_get("删除品目成功。")
    redirect_to kobe_categories_path(id: @category.parent_id)
  end

  # 冻结
  def freeze
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'freeze_category_form', action: update_freeze_kobe_category_path(@category) }
  end

  def update_freeze
    @category.change_status_and_write_logs("冻结", stateless_logs("冻结",params[:opt_liyou],false))
    @category.clean_cache_ids
    tips_get("冻结品目成功。")
    redirect_to kobe_categories_path(id: @category)
  end

  # 恢复
  def recover
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'recover_category_form', action: update_recover_kobe_category_path(@category) }
  end

  def update_recover
    @category.change_status_and_write_logs("恢复", stateless_logs("恢复",params[:opt_liyou],false))
    @category.clean_cache_ids
    tips_get("恢复品目成功。")
    redirect_to kobe_categories_path(id: @category)
  end

  def move
    ztree_move(Category)
  end

  def ztree
    ztree_nodes_json(Category)
  end

  # 验证品目名称
  def valid_name
    params[:obj_id] ||= 0
    render :text => valid_remote(Category, ["name = ? and id != ? and status <> 404", params[:categories][:name], params[:obj_id]])
  end

  private
    def get_category
      cannot_do_tips unless @category.present? && @category.cando(action_name)
    end

end
