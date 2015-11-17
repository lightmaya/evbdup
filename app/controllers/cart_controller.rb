# -*- encoding : utf-8 -*-

class CartController < JamesController
  before_filter :find_product_and_seller, :only => [:change]
  skip_filter :find_cart, :only => [:destroy]

  # 加入购物车
  def change
    @cart.change(@product, @seller, params[:num], params[:set].present?)
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
    Product.where("id in (?)", params[:pids].to_s.split("_")).each do |product|
      seller = product.item.agents.find_by_id(params[:seller_id])
      @cart.dynamic(product, seller, params[:ready] == "true")
    end
    save_cart
    render :json => {"success" => true}
  end

  def rm
    @cart.destroy(params[:id], params[:seller_id])
    save_cart
    redirect_to cart_path
  end

  def destroy
    cookies.delete :cart
    redirect_to cart_url, :notice => '购物车已经清空'
  end

  private

  def find_product_and_seller
    @product = Product.show.find_by_id(params[:id])
    return render_404 if @product.blank?

    @seller = if @procut.cjzx?
      @product.department_id
    else
      @product.item.agents.find_by_id(params[:seller_id])
    end

    return render_404 if @seller.blank?
  end
 
end
