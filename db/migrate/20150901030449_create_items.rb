# -*- encoding : utf-8 -*-
class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
    	t.string :name, :comment => "项目名称"
      t.boolean :item_type, :null => false, :default => false, :comment => "用户类型 0:厂家供货,1:代理商供货"
      t.date :begin_time, :comment => "有效期开始时间"
      t.date :end_time, :comment => "有效期截止时间"
      t.text :dep_names, :comment => "入围供应商名单"
      t.text :categoryids, :comment => "品目id" 
      t.integer :status, :comment => "状态", :limit => 2, :default => 0 , :null => false
      t.text :details, :comment => "明细"
      t.text :logs, :comment => "日志"

      t.timestamps
    end

    create_table :item_categories do |t|
    	t.belongs_to :item, :null => false
			t.belongs_to :category, :null => false

      t.timestamps
    end

    create_table :item_departments do |t|
    	t.belongs_to :item, :null => false
			t.belongs_to :department
			t.string :name, :comment => "单位名称"
      t.integer :rule_id, :comment => "流程ID"
      t.string :rule_step, :comment => "审核流程 例：start 、分公司审核、总公司审核、done"

      t.timestamps
    end
  end
end
