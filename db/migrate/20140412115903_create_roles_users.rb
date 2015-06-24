# -*- encoding : utf-8 -*-
class CreateRolesUsers < ActiveRecord::Migration
  def change
    create_table :roles_users do |t|
      t.belongs_to :user, :null => false
      t.belongs_to :role, :null => false
    end
    add_index :roles_users, [:user_id, :role_id]
  end
end