# -*- encoding : utf-8 -*-
class CreatePermissions < ActiveRecord::Migration
  def change
    create_table :permissions do |t|
    	t.string :name        , :comment => "名称", :null => false
			t.string :action      , :comment => "权限", :null => false
			t.string :subject     , :comment => "对象", :null => false
			t.boolean :is_model   , :comment => "是否类", :null => false, :default => 1
			t.string :conditions  , :comment => "条件"
			t.string :description , :comment => "描述"

      t.timestamps
    end
    add_index :permissions, :name
    add_index :permissions, [:action,:subject]
  end
end