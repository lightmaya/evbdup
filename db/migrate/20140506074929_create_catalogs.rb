# -*- encoding : utf-8 -*-
class CreateCatalogs < ActiveRecord::Migration
  def change
    create_table :catalogs do |t|
	  t.string :name                   , :comment => "名称", :null => false
	  t.string :ancestry               , :comment => "祖先节点"
	  t.integer :ancestry_depth        , :comment => "层级"
    t.string :icon                   , :comment => "图标"
    t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
	  t.integer :sort                  , :comment => "排序"
    t.text :params                   , :comment => "参数"
    t.timestamps
    end
    add_index :catalogs, :name,                :unique => true
  end
end
