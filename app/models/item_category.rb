# -*- encoding : utf-8 -*-
class ItemCategory < ActiveRecord::Base
	belongs_to :category
  belongs_to :item
  
end
