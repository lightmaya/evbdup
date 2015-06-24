# -*- encoding : utf-8 -*-
class CreateAreas < ActiveRecord::Migration
  def change
    create_table :areas do |t|
		t.string :name                   , :comment => "单位名称"
		t.string :ancestry               , :comment => "祖先节点"
		t.integer :ancestry_depth        , :comment => "层级"
		t.string :code                   , :comment => "编号"
		t.integer :sort                  , :comment => "排序"

    t.timestamps
    end
  end
end
