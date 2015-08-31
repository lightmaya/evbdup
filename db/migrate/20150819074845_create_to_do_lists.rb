# -*- encoding : utf-8 -*-
class CreateToDoLists < ActiveRecord::Migration
  def change
    create_table :to_do_lists do |t|
    	t.string :name, :comment => "名称"
      t.string :list_url, :comment => "列表url"
      t.string :audit_url, :comment => "审核url"
      t.integer :sort, :comment => "排序"
      t.integer :status, :comment => "状态", :limit => 2, :default => 0 , :null => false
      t.text :details, :comment => "明细"
      t.text :logs, :comment => "日志"

      t.timestamps
    end
  end
end
