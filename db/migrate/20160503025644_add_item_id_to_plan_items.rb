# -*- encoding : utf-8 -*-
class AddItemIdToPlanItems < ActiveRecord::Migration
  def change
    add_column :plan_items, :item_id, :integer, :comment => "入围项目ID"
    add_column :plan_item_categories, :department_id, :integer, :comment => "中标单位id"
    add_column :plan_item_categories, :dep_name, :string, :comment => "中标单位名称"
    add_column :orders, :plan_key, :string, :comment => "计划采购item_id_category_id"

    create_table :plan_item_results do |t|
      t.belongs_to :plan_item, :null => false
      t.belongs_to :category, :null => false
      t.string :category_name, :comment => "品目名称"
      t.text :name, :comment => "中标单位名称"
      t.text :dep_ids, :comment => "中标单位id"
      t.text :details, :comment => "明细"

      t.timestamps
    end
  end
end
