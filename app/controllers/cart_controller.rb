# -*- encoding : utf-8 -*-

class CartController < JamesController
  before_filter :find_product_and_agent, :only => [:change]
  skip_filter :find_cart, :only => [:destroy]

  # 加入购物车
  def change
    @cart.change(@product, @agent, params[:num], params[:set].present?)
    save_cart
    redirect_to cart_path
  end

  def show
    @step = 1
  end

  # 改变购买状态
  def dynamic
    Product.where("id in (?)", params[:pids].to_s.split("_")).each do |product|
      agent = product.item.agents.find_by_id(params[:agent_id])
      @cart.dynamic(product, agent, params[:ready] == "true")
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

  def find_product_and_agent
    @product = Product.show.find_by_id(params[:id])
    return render_404 if @product.blank?
    @agent = @product.item.agents.find_by_id(params[:agent_id])
    return render_404 if @agent.blank?
  end
 
end
