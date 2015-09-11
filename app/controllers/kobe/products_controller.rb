# -*- encoding : utf-8 -*-
class Kobe::ProductsController < KobeController

  before_action :get_item, :only => [:item_list, :new, :create]
  before_action :get_category, :only => [:new, :create]
  before_action :get_product, :except => [:index, :item_list, :get_item_category, :new, :create]
  skip_before_action :verify_authenticity_token, :only => [:commit]
  layout :false, :only => [:get_item_category]
  skip_authorize_resource :only => [:get_item_category]

  # 我的入围产品
  def index
    params[:q][:user_id_eq] = current_user.id
    @q = Product.where(get_conditions("products")).ransack(params[:q]) 
    @products = @q.result.page params[:page]
  end

  # 某项目入围产品
  def item_list
    params[:q][:user_id_eq] = current_user.id
    params[:q][:item_id_eq] = @item.id
    @q = Product.where(get_conditions("products")).ransack(params[:q]) 
    @products = @q.result.page params[:page]
  end

  # 新增产品前选择要新增产品的品目
  def get_item_category
    @item = Item.find_by(id: params[:item_id]) if params[:item_id].present?
  end

  def new
    @product.brand = current_user.department.short_name unless @item.item_type
    @myform = SingleForm.new(@category.params_xml, @product, { form_id: "product_form", upload_files: true, min_number_of_files: 1, action: kobe_products_path(item_id: @item.id, category_id: @category.id), title: "<i class='fa fa-pencil-square-o'></i> 新增产品--#{@category.name}", grid: 4 })
  end

  def create
    create_and_write_logs(Product, @category.params_xml, {}, { item_id: @item.id, category_id: @category.id, category_code: @category.ancestry, department_id: current_user.department.id })
    redirect_to item_list_kobe_products_path(item_id: @item.id) 
  end

  def update
    update_and_write_logs(@product, @product.category.params_xml)
    redirect_to item_list_kobe_products_path(item_id: @product.item.id) 
  end

  def edit
    @myform = SingleForm.new(@product.category.params_xml, @product, { form_id: "product_form", upload_files: true, min_number_of_files: 1, action: kobe_product_path(@product), method: "patch", title: "<i class='fa fa-pencil-square-o'></i> 修改产品--#{@product.category.name}", grid: 4 })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@product,@product.category.params_xml) }
    @arr << { title: "附件", icon: "fa-paperclip", content: show_uploads(@product,true) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@product) }
  end

  # 提交
  def commit
    @product.change_status_and_write_logs("提交",stateless_logs("提交","提交成功！", false))
    # 插入产品审核的待办事项
    
    tips_get("提交成功！")
    redirect_back_or
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_product_form', action: kobe_product_path(@product), method: 'delete' }
  end

  def destroy
    @product.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_back_or request.referer
  end

  # 冻结
  def freeze
    render partial: '/shared/dialog/opt_liyou', locals: {form_id: 'freeze_product_form', action: update_freeze_kobe_product_path(@product)}
  end

  def update_freeze
    @product.change_status_and_write_logs("冻结",stateless_logs("冻结", params[:opt_liyou], false))
    tips_get("冻结成功。")
    redirect_back_or request.referer
  end

  # 恢复
  def recover
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'recover_product_form', action: update_recover_kobe_product_path(@product) }
  end

  def update_recover
    @product.change_status_and_write_logs("恢复", stateless_logs("恢复",params[:opt_liyou],false))
    tips_get("恢复成功。")
    redirect_back_or request.referer
  end

  private

    def get_item
      @item = Item.find_by(id: params[:item_id]) if params[:item_id].present?
      cannot_do_tips unless @item.present? && @item.finalist?(current_user.department.id)
    end

    def get_category
      @category = Category.find_by(id: params[:category_id]) if params[:category_id].present?
      cannot_do_tips if @category.blank?
    end

    def get_product
      cannot_do_tips unless @product.present? && @product.cando(action_name,current_user)
    end

end
