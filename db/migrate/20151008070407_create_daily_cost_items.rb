# -*- encoding : utf-8 -*-
class CreateDailyCostItems < ActiveRecord::Migration
	def change
		create_table :daily_cost_items do |t|
			t.belongs_to :daily_cost,    	index: true , :comment => "订单ID", :null => false, :default => 0
			t.belongs_to :daily_category, index: true , :comment => "品目"
			t.string :category_code   , :comment => "品目ancestry", :null => false
			t.string :category_name   , :comment => "品目名称"
			t.string :daily_xm   , :comment => "项目" 
			t.decimal :total          , :comment => "总金额", :precision => 13, :scale => 2, :null => false, :default => 0
			t.text :summary           , :comment => "基本情况（备注）"
			t.text :details           , :comment => "明细"
			t.timestamps
		end
	end
end
