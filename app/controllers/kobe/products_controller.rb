# -*- encoding : utf-8 -*-
class Kobe::ProductsController < KobeController

  before_action :get_product, :only => [:show, :edit, :update]

  def index
    @products = Product.where(get_conditions).page params[:page]
  end

  def new
  	product = Product.new
  	category = Category.find(params[:id])
  	product.category_id = params[:id]
    @myform = SingleForm.new(category.params, product, { form_id: "product_form", upload_files: true, action: kobe_products_path(id: category), title: '<i class="fa fa-pencil-square-o"></i> 新增产品', grid: 4 })
  end

  def create
  	category = Category.find(params[:id])
    product = create_and_write_logs(Product, category.params, {}, {category_id: category.id})
    if product
      redirect_to kobe_products_path
    else
      redirect_to root_path
    end
  end

  def update
    if update_and_write_logs(@product, @product.category.params)
      redirect_to kobe_products_path
    else
      redirect_back_or
    end
  end

  def edit
    @myform = SingleForm.new(@product.category.params, @product, { form_id: "product_form", upload_files: true, action: kobe_product_path(@product), method: "patch", title: '<i class="fa fa-pencil-square-o"></i> 修改产品', grid: 4 })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@product,@product.category.params) }
    @arr << { title: "附件", icon: "fa-paperclip", content: show_uploads(@product,true) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@product) }
  end

  # 冻结
  def freeze
    Product.batch_change_status_and_write_logs(params[:id_array].split(","), "冻结", stateless_logs("冻结",params[:opt_liyou]))
    redirect_to kobe_products_path
  end

  # 删除
  def delete
    Product.batch_change_status_and_write_logs(params[:id_array].split(","), "已删除", stateless_logs("删除",params[:opt_liyou]))
    redirect_to kobe_products_path
  end

  # 恢复
  def recover
    Product.batch_change_status_and_write_logs(params[:id_array].split(","), "正常", stateless_logs("恢复",params[:opt_liyou]))
    redirect_to kobe_products_path
  end

  private

  def get_product
    @product = Product.find(params[:id]) unless params[:id].blank? 
  end

end