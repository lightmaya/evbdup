# -*- encoding : utf-8 -*-
class CreateBudgets < ActiveRecord::Migration
  def change
    create_table :budgets do |t|
      t.belongs_to :order
      t.integer :rule_id               , :comment => "流程ID"
      t.string :rule_step              , :comment => "审核流程 例：start 、分公司审核、总公司审核、done"
      t.belongs_to :department
      t.string :dep_code               , :comment => "采购单位real_ancestry"
      t.string :name                   , :comment => "名称", :null => false
      t.decimal :budget                , :comment => "总预算金额", :precision => 13, :scale => 2, :null => false, :default => 0
      t.text :summary                  , :comment => "基本情况（备注）"
      t.belongs_to :user               , :comment => "用户ID", :null => false, :default => 0
      t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
      t.text :details                  , :comment => "明细"
      t.text :logs                     , :comment => "日志"

      t.timestamps
    end

    create_table :budget_uploads do |t|
      t.belongs_to :master, :default => 0
      t.string   "upload_file_name"   , :comment => "文件名称"
      t.string   "upload_content_type", :comment => "文件类型"
      t.integer  "upload_file_size"   , :comment => "文件大小"
      t.datetime "upload_updated_at"  , :comment => "时间戳"
      t.timestamps
    end
  end
end
