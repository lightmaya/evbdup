# -*- encoding : utf-8 -*-
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
    	t.belongs_to :item, :default => 0, :comment => "项目ID", :null => false
		t.belongs_to :category, :default => 0, :comment => "品目ID", :null => false
		t.string :category_code, :comment => "品目编号", :default => 0, :null => false
    	t.string :brand, :comment => "品牌"
    	t.string :model, :comment => "型号"
    	t.string :version, :comment => "版本号"
    	t.string :unit, :comment => "计量单位"
    	t.decimal :market_price, :precision => 13, :scale => 2, :comment => "市场价格"
    	t.decimal :bid_price, :precision => 13, :scale => 2, :comment => "中标价格"
    	t.text :summary, :comment => "基本描述"
    	t.integer :status, :comment => "状态", :limit => 2, :default => 0,:null => false
    	t.text :details, :comment => "明细"
        t.belongs_to :user, :default => 0, :comment => "用户ID", :null => false
    	t.text :logs, :comment => "日志"
      t.timestamps
    end
  end
end
