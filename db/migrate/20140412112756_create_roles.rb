# -*- encoding : utf-8 -*-
class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
		  t.string :name                   , :comment => "名称", :null => false
		  t.string :ancestry               , :comment => "祖先节点"
		  t.integer :ancestry_depth        , :comment => "层级"
	    t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
      t.string :menuids               , :comment => "菜单ID", :limit => 800
		  t.integer :sort                  , :comment => "排序"
      t.text :details                  , :comment => "明细"
      t.text :logs                     , :comment => "日志"
      
      t.timestamps
    end
    add_index :roles, :name
  end
end