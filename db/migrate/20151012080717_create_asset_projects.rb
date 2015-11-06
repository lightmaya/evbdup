class CreateAssetProjects < ActiveRecord::Migration
	def change
		create_table :asset_projects do |t|
			t.integer :rule_id               , :comment => "流程ID"
			t.string :rule_step              , :comment => "审核流程 例：start 、分公司审核、总公司审核、done"
			t.string :name                   , :comment => "名称", :null => false
			t.string :sn                     , :comment => "凭证编号（验收单号）"
			t.belongs_to :department
			t.string :dep_name             , :comment => "采购单位名称"
			t.string :dep_code             , :comment => "采购单位real_ancestry"
			t.string :dep_man              , :comment => "采购单位联系人"
			t.decimal :total                 , :comment => "总金额", :precision => 13, :scale => 2, :null => false, :default => 0
			t.date :deliver_at		           , :comment => "报销时间"
			t.text :summary                  , :comment => "基本情况（备注）"
			t.belongs_to :user               , :comment => "用户ID", :null => false, :default => 0
			t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
			t.text :details                  , :comment => "明细"
			t.text :logs 			
			t.timestamps			
		end
	end
end
