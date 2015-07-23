# -*- encoding : utf-8 -*-
class UserRole < ActiveRecord::Base
	belongs_to :role
  belongs_to :user
end
