class CreateRoleMenus < ActiveRecord::Migration
  def change
    create_table :role_menus do |t|
			t.belongs_to :role, :null => false
      t.belongs_to :menu, :null => false

      t.timestamps
    end

    add_index :role_menus, [:menu_id]
    add_index :role_menus, [:role_id]
    add_index :role_menus, [:menu_id, :role_id] , :unique => true
  end
end
