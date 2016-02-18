# -*- encoding : utf-8 -*-
class AddIsClassifyToItems < ActiveRecord::Migration
  def change
    add_column :items, :is_classify, :boolean, :default => 0, :comment => "入围供应商是否分级", :null => false
    add_column :item_departments, :classify, :integer, :default => 0, :comment => "入围供应商分级 1:A级 2:B级 3:C级 0:待定", :null => false
  end
end
