# -*- encoding : utf-8 -*-
class PlanItemCategory < ActiveRecord::Base
  belongs_to :category
  belongs_to :plan_item
  
end
