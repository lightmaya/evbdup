# -*- encoding : utf-8 -*-
class AddIndexToMenus < ActiveRecord::Migration
  def change

    add_index :menus, :route_path
    add_index :menus, :user_type

  end
end
