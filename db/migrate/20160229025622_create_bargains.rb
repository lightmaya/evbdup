# -*- encoding : utf-8 -*-
class CreateBargains < ActiveRecord::Migration
  def change
    create_table :bargains do |t|
      t.belongs_to :category, :default => 0, :comment => "品目ID", :null => false
      t.string :category_code, :comment => "品目编号", :default => 0, :null => false
      t.integer :rule_id               , :comment => "流程ID"
      t.string :rule_step              , :comment => "审核流程 例：start 、分公司审核、总公司审核、done"
      t.string :name                   , :comment => "名称", :null => false
      t.string :sn                     , :comment => "协议议价编号"
      t.belongs_to :department
      t.string :dep_name             , :comment => "采购单位名称"
      t.string :dep_code             , :comment => "采购单位real_ancestry"
      t.string :dep_man              , :comment => "采购单位联系人"
      t.string :dep_tel              , :comment => "采购单位联系人座机"
      t.string :dep_mobile           , :comment => "采购单位联系人手机"
      t.belongs_to :budget
      t.decimal :total                 , :comment => "总预算金额", :precision => 13, :scale => 2, :null => false, :default => 0
      t.text :summary                  , :comment => "基本情况（备注）"
      t.belongs_to :user               , :comment => "用户ID", :null => false, :default => 0
      t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
      t.text :details                  , :comment => "明细"
      t.text :logs                     , :comment => "日志"
      t.timestamps
    end

    create_table :bargain_products do |t|
      t.belongs_to :bargain        , :comment => "协议议价ID", :null => false, :default => 0
      t.decimal :quantity, :comment => "数量", :precision => 13, :scale => 3, :null => false, :default => 0
      t.string :unit            , :comment => "计量单位"
      t.text :details           , :comment => "明细"
      t.timestamps
    end

    create_table :bargain_uploads do |t|
      t.belongs_to :master, :default => 0
      t.string   "upload_file_name"   , :comment => "文件名称"
      t.string   "upload_content_type", :comment => "文件类型"
      t.integer  "upload_file_size"   , :comment => "文件大小"
      t.datetime "upload_updated_at"  , :comment => "时间戳"
      t.timestamps
    end

    add_index :bargain_uploads, [:master_id]
    add_index :bargain_products, :bargain_id
    add_index :bargains, :sn, :unique => true
    add_index :bargains, :budget_id
  end
end
