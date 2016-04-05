# -*- encoding : utf-8 -*-
class MallToken < ActiveRecord::Base

  scope :mall, -> { where(name: 'mall') }
  scope :govbuy, -> { where(name: 'govbuy') }
  scope :order_token, -> { where(name: 'order') }

end
