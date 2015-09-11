class RemoveRuleIdFromItemDepartments < ActiveRecord::Migration
  def change
    remove_column :item_departments, :rule_id, :integer
    remove_column :item_departments, :rule_step, :string
  end
end
