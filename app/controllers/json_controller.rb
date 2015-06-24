# -*- encoding : utf-8 -*-
class JsonController < ApplicationController
	layout false 

  def areas
  	ztree_json(Area)
  end

  def menus
  	ztree_json(Menu)
  end

  def categories
  	ztree_json(Category)
  end

  def roles
  	ztree_json(Role)
  end

end
