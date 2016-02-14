# -*- encoding : utf-8 -*-
class UserCategory < ActiveRecord::Base
  belongs_to :category
  belongs_to :user
end
