# -*- encoding : utf-8 -*-
class AddRuleIdToArticles < ActiveRecord::Migration
  def change
  	add_column :articles, :rule_id, :integer, :comment => "流程ID"
  	add_column :articles, :rule_step, :string, :comment => "审核流程 例：start 、分公司审核、总公司审核、done"
  	add_index :articles, :rule_step
  	add_index :articles, :rule_id
  end
end
