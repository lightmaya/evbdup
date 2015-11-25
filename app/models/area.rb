# -*- encoding : utf-8 -*-
class Area < ActiveRecord::Base
  # 树形结构
  has_ancestry :cache_depth => true
  # default_scope -> {order(:ancestry, :sort, :id)}

  include AboutAncestry

  # [一级, 二级, 三级]
  def pcc
    self.path.where("ancestry_depth in (2,3,4)")
  end

  def self.fix
     Area.find_each.each do |area|
      area.pcc_ids = area.pcc.map(&:id).join("-")
      area.pcc_name = area.pcc.map(&:pet_name).join("-")
      area.save
    end
  end
  
end
