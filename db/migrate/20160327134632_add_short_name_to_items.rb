# -*- encoding : utf-8 -*-
class AddShortNameToItems < ActiveRecord::Migration
  def change
    add_column :items, :short_name, :string, :comment => "项目别名"
  end
end
