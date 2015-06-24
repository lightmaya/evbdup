# -*- encoding : utf-8 -*-
class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
    	t.string :name                   , :comment => "名称", :null => false
    	t.string :sn                     , :comment => "凭证编号（验收单号）"
        t.string :contract_sn            , :comment => "合同编号"
    	t.string :buyer                  , :comment => "采购单位名称"
        t.string :payer                  , :comment => "发票抬头"
    	t.string :buyer_code             , :comment => "采购单位编号"
    	t.string :seller                 , :comment => "供应商单位名称"
    	t.string :seller_code            , :comment => "供应商单位编号"
        t.decimal :bugget, :precision => 13, :scale => 2, :comment => "总预算"
    	t.decimal :total, :precision => 13, :scale => 2, :null => false, :default => 0, :comment => "总金额"
    	t.date :deliver_at		     , :comment => "交付时间"
    	t.string :invoice_number         , :comment => "发票编号"
    	t.text :summary                  , :comment => "基本情况（备注）"
    	t.belongs_to :user, :default => 0, :comment => "用户ID", :null => false
    	t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
    	t.datetime :effective_time			 , :comment => "生效时间（统计）"
    	t.text :details                  , :comment => "明细"
    	t.text :logs                     , :comment => "日志"
      t.timestamps
    end
    add_index :orders, :sn, :unique => true
  end
end