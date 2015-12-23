# -*- encoding : utf-8 -*-
class AddRuleIdToBidProjects < ActiveRecord::Migration
  def change
    add_column :bid_projects, :rule_id, :integer
    add_column :bid_projects, :rule_step, :string
    add_column :bid_projects, :budget_id, :integer
    add_index :bid_projects, :budget_id
    rename_column :bid_projects, :budget, :budget_money
  end
end
