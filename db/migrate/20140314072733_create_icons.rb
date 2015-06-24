# -*- encoding : utf-8 -*-
class CreateIcons < ActiveRecord::Migration
  def change
    create_table :icons do |t|
		  t.string :name                   , :comment => "名称", :null => false
		  t.string :ancestry               , :comment => "祖先节点"
		  t.integer :ancestry_depth        , :comment => "层级"
	    t.string :transfer               , :comment => "实际图标，父级节点的name不是真正的图标"
	    t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
		  t.integer :sort                  , :comment => "排序"
    end
    add_index :icons, :name,                :unique => true
  end
end