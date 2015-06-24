# -*- encoding : utf-8 -*-
class CreateOrdersProducts < ActiveRecord::Migration
  def change
    create_table :orders_products do |t|
    	t.belongs_to :order, :default => 0  , :comment => "订单ID", :null => false
    	t.string :category_code							, :comment => "品目编号", :null => false
    	t.belongs_to :product, :default => 0, :comment => "产品ID", :null => false
    	t.string :brand                     , :comment => "品牌"
    	t.string :model                     , :comment => "型号"
    	t.string :version                   , :comment => "版本号"
    	t.string :unit                   	, :comment => "计量单位"
    	t.decimal	:market_price, :precision => 13, :scale => 2, :comment => "市场价格"
    	t.decimal	:bid_price, :precision => 13, :scale => 2, :comment => "中标价格"
    	t.decimal	:price, :precision => 13, :scale => 2, :null => false, :default => 0, :comment => "成交价格"
    	t.integer :quantity                 , :comment => "数量", :default => 0 ,:null => false
    	t.decimal	:total, :precision => 13, :scale => 2, :null => false, :default => 0, :comment => "总金额"
        t.text :summary                  , :comment => "基本情况（备注）"
        t.text :details                  , :comment => "明细"
      t.timestamps
    end
    add_index :orders_products, :order_id
    add_index :orders_products, :category_code
  end
end