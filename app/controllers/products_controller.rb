# -*- encoding : utf-8 -*-
class ProductsController < JamesController
	def show
		@product = Product.show.find_by_id(params[:id])
		redirect_to not_found_path unless @product
	end
end
