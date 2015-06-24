# -*- encoding : utf-8 -*-
class CreatePermissionsRoles < ActiveRecord::Migration
  def change
    create_table :permissions_roles do |t|
      t.belongs_to :role, :null => false
      t.belongs_to :permission, :null => false
    end
    add_index :permissions_roles, [:role_id, :permission_id]
  end
end