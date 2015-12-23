# -*- encoding : utf-8 -*-
class CreateAssetProjectItems < ActiveRecord::Migration
  def change
    create_table :asset_project_items do |t|
      t.belongs_to :asset_project,    	index: true , :comment => "项目ID", :null => false, :default => 0
			t.belongs_to :fixed_asset, index: true , :comment => "品目"
			t.string :asset_name   , :comment => "车类别"
			t.decimal :total          , :comment => "总金额", :precision => 13, :scale => 2, :null => false, :default => 0
			t.text :details           , :comment => "明细"
			t.timestamps
    end
  end
end
