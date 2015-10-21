# -*- encoding : utf-8 -*-
class AddItemIdToBidProjects < ActiveRecord::Migration
  def change
  	add_column :bid_projects, :item_id, :integer, :comment => "指定供应商的项目"
  	add_index :bid_projects, :item_id
  	add_column :users, :cart, :text
  end
end
