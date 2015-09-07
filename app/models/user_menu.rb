# -*- encoding : utf-8 -*-
class UserMenu < ActiveRecord::Base
	belongs_to :menu
  belongs_to :user
end
