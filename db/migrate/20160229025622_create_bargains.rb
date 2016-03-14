# -*- encoding : utf-8 -*-
class CreateBargains < ActiveRecord::Migration
  def change
    change_column :bid_project_bids, :is_bid, :boolean, :default => 0 ,:null => false
    change_column :categories, :show_plan, :integer, :comment => "业务类型, 对应 Dictionary.category_yw_type"
    rename_column :categories, :show_plan, :yw_type

    create_table :bargains do |t|
      t.belongs_to :item, :default => 0, :comment => "项目ID", :null => false
      t.belongs_to :category, :default => 0, :comment => "品目ID", :null => false
      t.string :category_code, :comment => "品目编号", :default => 0, :null => false
      t.integer :rule_id               , :comment => "流程ID"
      t.string :rule_step              , :comment => "审核流程 例：start 、分公司审核、总公司审核、done"
      t.string :name                   , :comment => "名称", :null => false
      t.string :sn                     , :comment => "协议议价编号"
      t.belongs_to :department
      t.string :dep_name             , :comment => "采购单位名称"
      t.string :invoice_title           , :comment => "发票抬头"
      t.string :dep_code             , :comment => "采购单位real_ancestry"
      t.string :dep_man              , :comment => "采购单位联系人"
      t.string :dep_tel              , :comment => "采购单位联系人座机"
      t.string :dep_mobile           , :comment => "采购单位联系人手机"
      t.string :dep_addr              , :comment => "单位地址"
      t.belongs_to :budget
      t.decimal :total                 , :comment => "总预算金额", :precision => 13, :scale => 2
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
    add_index :bargains, :department_id
    add_index :bargains, :dep_code
    add_index :bargains, :category_id
    add_index :bargains, :item_id

    create_table :bargain_bids do |t|
      t.belongs_to :bargain        , :comment => "协议议价ID", :null => false, :default => 0
      t.belongs_to :department
      t.string :name, :comment => "供应商单位"
      t.string :dep_man              , :comment => "供应商联系人"
      t.string :dep_tel              , :comment => "供应商联系人座机"
      t.string :dep_mobile           , :comment => "供应商联系人手机"
      t.string :dep_addr           , :comment => "供应商联系人地址"
      t.text :details
      t.integer :user_id
      t.boolean :is_bid, :comment => "是否中标", :default => 0 ,:null => false
      t.datetime :bid_time, :comment => "报价时间"
      t.decimal :total, :comment => "总金额", :precision => 20, :scale => 2, :null => false, :default => 0
      t.decimal :deliver_fee, :comment => "运费", :precision => 20, :scale => 2
      t.decimal :other_fee, :comment => "其他费用", :precision => 20, :scale => 2
      t.string :other_fee_desc, :comment => "其他费用说明"
      t.text :logs

      t.timestamps
    end

    add_index :bargain_bids, :bargain_id
    add_index :bargain_bids, :department_id
    add_index :bargain_bids, [:bargain_id, :department_id], :unique => true


    create_table :bargain_bid_products do |t|
      t.belongs_to :bargain_bid        , :comment => "协议议价报价ID", :null => false, :default => 0
      t.belongs_to :bargain_product        , :comment => "协议议价产品ID", :null => false, :default => 0
      t.belongs_to :product
      t.text :details
      t.decimal :price, :comment => "单价", :precision => 20, :scale => 2, :null => false, :default => 0
      t.decimal :total, :comment => "总价", :precision => 20, :scale => 2, :null => false, :default => 0
    end

    add_index :bargain_bid_products, :bargain_bid_id
    add_index :bargain_bid_products, :bargain_product_id
    add_index :bargain_bid_products, :product_id
    add_index :bargain_bid_products, [:bargain_product_id, :product_id], :unique => true

  end
end
