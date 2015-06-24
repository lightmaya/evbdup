# -*- encoding : utf-8 -*-
class CreateMenusUsers < ActiveRecord::Migration
  def change
    create_table :menus_users do |t|
      t.belongs_to :user, :null => false
      t.belongs_to :menu, :null => false
    end
    add_index :menus_users, [:user_id, :menu_id]
  end
end
