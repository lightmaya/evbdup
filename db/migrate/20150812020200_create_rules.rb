# -*- encoding : utf-8 -*-
class CreateRules < ActiveRecord::Migration
  def change
    create_table :rules do |t|
      t.string :name, :comment => "名称"
      t.text :rule, :comment => "规则"
      t.text :audit_reason, :comment => "审核理由"
      t.integer :status, :comment => "状态", :limit => 2, :default => 0 , :null => false
      t.text :details, :comment => "明细"
      t.text :logs, :comment => "日志"

      t.timestamps
    end
  end
end
