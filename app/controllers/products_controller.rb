# -*- encoding : utf-8 -*-
class ProductsController < JamesController

  def show
    @product = Product.show.find_by_id(params[:id])
    redirect_to errors_path(no: 404) unless @product
  end

  # def get_prices
  #   # return render :json => {"success" => false} unless current_user
  #   @products = Product.where("id in (?)", params[:ids].split(","))
  #   rs = []
  #   @products.each do |pr|
  #     rs << {"id" => pr.id, "bid_price" => ApplicationController.helpers.money(pr.bid_price), "market_price" => ApplicationController.helpers.money(pr.market_price)}
  #   end
  #   render :json => {"success" => true, "rs" => rs}
  # end
end
