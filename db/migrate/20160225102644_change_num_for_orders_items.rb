# -*- encoding : utf-8 -*-
class ChangeNumForOrdersItems < ActiveRecord::Migration
  def change
    change_column :orders_items, :quantity, :decimal, :comment => "数量", :precision => 13, :scale => 3, :null => false, :default => 0
    change_column :plan_products, :quantity, :decimal, :comment => "数量", :precision => 13, :scale => 3, :null => false, :default => 0
    change_column :bid_items, :num, :decimal, :comment => "数量", :precision => 13, :scale => 3, :null => false, :default => 0
    change_column :transfer_items, :num, :decimal, :comment => "数量", :precision => 13, :scale => 3, :null => false, :default => 0
  end
end
