# -*- encoding : utf-8 -*-
class RoleMenu < ActiveRecord::Base
	belongs_to :role
  belongs_to :menu
end
