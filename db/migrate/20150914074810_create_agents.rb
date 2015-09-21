# -*- encoding : utf-8 -*-
class CreateAgents < ActiveRecord::Migration
  def change
    create_table :agents do |t|
      t.belongs_to :item, :default => 0, :comment => "项目ID", :null => false
      t.belongs_to :department, :default => 0, :comment => "单位ID", :null => false
      t.integer :agent_id, :default => 0, :comment => "代理商单位ID", :null => false
      t.string :name, :comment => "代理商名称", :null => false
      t.text :area_id, :comment => "地区id"
      t.integer :status, :comment => "状态", :limit => 2, :default => 0,:null => false
      t.text :details, :comment => "明细"
      t.belongs_to :user, :default => 0, :comment => "用户ID", :null => false
      t.text :logs, :comment => "日志"

      t.timestamps
    end
  end
end
