# -*- encoding : utf-8 -*-
class AddRuleIdToProducts < ActiveRecord::Migration
  def change
    add_column :products, :rule_id, :integer
    add_column :products, :rule_step, :string
  end
end
