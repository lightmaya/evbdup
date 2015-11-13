# -*- encoding : utf-8 -*-
class Kobe::MainController < KobeController

	skip_load_and_authorize_resource 
	
  def index
  	@orders = current_user.department.buyer_orders.limit(5)
  end

  def to_do
  	
  end
end
