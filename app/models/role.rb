# -*- encoding : utf-8 -*-
class Role < ActiveRecord::Base
  has_and_belongs_to_many  :users
  has_and_belongs_to_many  :permissions
  # 树形结构
  has_ancestry :cache_depth => true
  default_scope -> {order(:ancestry, :sort, :id)}

  include AboutAncestry

  private

end
