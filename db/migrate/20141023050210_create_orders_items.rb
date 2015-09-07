# -*- encoding : utf-8 -*-
class CreateOrdersItems < ActiveRecord::Migration
  def change
    create_table :orders_items do |t|
    	t.belongs_to :order       , :comment => "订单ID", :null => false, :default => 0
        t.belongs_to :category    , :comment => "品目"
    	t.string :category_code   , :comment => "品目ancestry", :null => false
        t.string :category_name   , :comment => "品目名称"
    	t.belongs_to :product     , :comment => "产品ID", :null => false, :default => 0
    	t.string :brand           , :comment => "品牌"
    	t.string :model           , :comment => "型号"
    	t.string :version         , :comment => "版本号"
    	t.string :unit            , :comment => "计量单位"
    	t.decimal :market_price   , :comment => "市场价格", :precision => 13, :scale => 2
    	t.decimal :bid_price      , :comment => "中标价格", :precision => 13, :scale => 2
    	t.decimal :price          , :comment => "成交价格", :precision => 13, :scale => 2, :null => false, :default => 0
    	t.integer :quantity       , :comment => "数量", :default => 0 ,:null => false
    	t.decimal :total          , :comment => "总金额", :precision => 13, :scale => 2, :null => false, :default => 0
        t.text :summary           , :comment => "基本情况（备注）"
        t.text :details           , :comment => "明细"
      t.timestamps
    end
    add_index :orders_items, :order_id
    add_index :orders_items, :category_code
  end
end
