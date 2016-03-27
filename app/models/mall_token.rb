# -*- encoding : utf-8 -*-
class MallToken < ActiveRecord::Base

  scope :login_token, -> { find_by(name: 'login') }
  scope :order_token, -> { find_by(name: 'order') }

end
