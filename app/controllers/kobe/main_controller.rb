# -*- encoding : utf-8 -*-
class Kobe::MainController < KobeController
  def index
  	@ca = "#{controller_name}_#{action_name}"
  end

  def to_do
  	
  end
end
