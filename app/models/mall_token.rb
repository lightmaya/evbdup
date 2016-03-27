# -*- encoding : utf-8 -*-
class MallToken < ActiveRecord::Base

  scope :login_token, -> { where(name: 'login') }
  scope :order_token, -> { where(name: 'order') }

end
