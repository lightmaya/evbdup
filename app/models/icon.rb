# -*- encoding : utf-8 -*-
class Icon < ActiveRecord::Base
  # 树形结构
  has_ancestry :cache_depth => true
  default_scope -> {order(:ancestry, :sort, :id)}
  scope :leaves, -> {where(:ancestry_depth => 1)}

end
