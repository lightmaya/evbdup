# -*- encoding : utf-8 -*-
class PlanItemResult < ActiveRecord::Base
  belongs_to :category
  belongs_to :plan_item

  before_create do
    self.category_name = Category.find_by(id: self.category_id).try(:name)
  end

  before_save do
    if self.name.present?
      names = self.name.split(",")
      # 删除不是本次填写的供应商名称
      all_names = PlanItemCategory.where(plan_item_id: self.plan_item_id, category_id: self.category_id).map(&:dep_name)
      PlanItemCategory.destroy_all(plan_item_id: self.plan_item_id, category_id: self.category_id, dep_name: (all_names - names))

      names.each do |n|
        dep = Department.find_by(name: n, ancestry: Dictionary.dep_supplier_id)
        tmp = { plan_item_id: self.plan_item_id, category_id: self.category_id, dep_name: n }
        tmp[:department_id] = dep.id if dep.present?
        PlanItemCategory.find_or_create_by(tmp)
      end
    end
  end

  def self.xml(obj='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node column='id' data_type='hidden'/>
        <node name='品目' column='category_name' class='required' display='readonly'/>
        <node column='dep_ids' data_type='hidden'/>
        <node name='中标供应商' column='name' class='box_checkbox required' json_url='/kobe/plan_items/dep_ztree_json' json_params='{"id": #{obj.try(:item_id)}}' partner='dep_ids'/>
      </root>
    }
  end

end
