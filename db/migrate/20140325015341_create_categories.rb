# -*- encoding : utf-8 -*-
class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
        t.string :name                   , :comment => "名称", :null => false
        t.string :ancestry               , :comment => "祖先节点"
        t.integer :ancestry_depth        , :comment => "层级"
        t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
        t.integer :sort                  , :comment => "排序"
        t.text :params              , :comment => "参数"
        t.text :details                  , :comment => "明细"
        t.belongs_to :user, :default => 0, :comment => "用户ID", :null => false
        t.text :logs                     , :comment => "日志"
        t.timestamps
    end
    add_index :categories, :name,                :unique => true
  end
end
