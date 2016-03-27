# -*- encoding : utf-8 -*-
class CartController < JamesController
  # before_filter :find_product_and_seller, :only => [:change]
  before_action :request_purchaser!
  skip_filter :find_cart, :only => [:destroy]

  # 加入购物车
  def change
    product_id = params[:id].to_s.split("-")[0]
    seller_id = params[:id].to_s.split("-")[2]
    product = Product.show.find_by(id: product_id)
    seller = Department.find_by(id: seller_id)
    @cart.change(product, seller, params[:num], params[:set].present?)
    save_cart
    if params[:a].present?
      return render nothing: true
    else
      return redirect_to cart_path
    end
  end

  def show

  end

  # 改变购买状态
  def dynamic
    params[:cart_item_ids].to_s.split("_").each do |cart_item_id|
      @cart.dynamic(cart_item_id, params[:ready] == "true")
    end
    save_cart
    render :json => {"success" => true}
  end

  def rm
    @cart.destroy(params[:id])
    save_cart
    redirect_to cart_path
  end

  def destroy
    cookies.delete :cart
    redirect_to cart_url, :notice => '购物车已经清空'
  end

  private
    # 需要采购人登录
    def request_purchaser!
      unless signed_in?
        flash_get '请先登录!'
        redirect_to sign_in_users_path
      else
        if current_user.department.is_dep_supplier?
          flash_get '供应商不能下单!'
          redirect_to root_path
        end
      end
    end
  # def find_product_and_seller
  #   product_id = params[:id].to_s.split("-")[0]
  #   seller_id = params[:id].to_s.split("-")[2]
  #   @product = Product.show.find_by_id(product_id)
  #   return render_404 if @product.blank?

  #   @seller = if @product.cjzx?
  #     @product.department
  #   else
  #     @product.item.agents.find_by_agent_id(seller_id).try(:agent_dep)
  #   end

  #   return render_404 if @seller.blank?
  # end

end
