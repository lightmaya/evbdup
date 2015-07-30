# -*- encoding : utf-8 -*-
class CreateMenus < ActiveRecord::Migration
  def change
    create_table :menus do |t|
    t.string :name                   , :comment => "名称", :null => false
    t.string :ancestry               , :comment => "祖先节点"
    t.integer :ancestry_depth        , :comment => "层级"
    t.string :icon                   , :comment => "图标"
    t.string :route_path             , :comment => "url"
    t.string :can_opt_action         , :comment => "用于cancancan判断用户是否有这个操作 例如：Department|update"
    t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
    t.integer :sort                  , :comment => "排序"
    t.boolean :is_show, :null => false, :default => false, :comment => "是否显示菜单"
    t.boolean :is_auto, :null => false, :default => false, :comment => "是否自动获取"
    t.boolean :is_blank, :null => false, :default => false, :comment => "是否弹出新页面"
    t.text :details                  , :comment => "明细"
    t.text :logs                     , :comment => "日志"
    
    t.timestamps
    end
    # add_index :menus, :name,                :unique => true
  end
end