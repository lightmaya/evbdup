# -*- encoding : utf-8 -*-
class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
        t.string :name             , :comment => "名称", :null => false
        t.string :ancestry         , :comment => "祖先节点"
        t.integer :ancestry_depth  , :comment => "层级"
        t.integer :audit_type      , :comment => "审核部门 -1：分公司审核，0：分公司审完总公司审，1：总公司审核"
        t.integer :status          , :comment => "状态", :limit => 2, :default => 0 , :null => false
        t.string :ht_template      , :comment => "合同模板", :default => "common", :null => false
        t.boolean :show_mall       , :comment => "显示在首页", :null => false, :default => false
        t.boolean :show_plan       , :comment => "采购计划显示", :null => false, :default => false
        t.integer :sort            , :comment => "排序"
        t.text :params_xml         , :comment => "参数"
        t.text :details            , :comment => "明细"
        t.text :logs               , :comment => "日志"
        t.timestamps
    end
    add_index :categories, :name,                :unique => true
  end
end
