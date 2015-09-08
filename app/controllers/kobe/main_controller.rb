# -*- encoding : utf-8 -*-
class Kobe::MainController < KobeController

	skip_load_and_authorize_resource 
	
  def index
  	@ca = "#{controller_name}_#{action_name}"
  end

  def to_do
  	
  end
end
