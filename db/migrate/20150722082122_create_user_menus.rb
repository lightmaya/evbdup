class CreateUserMenus < ActiveRecord::Migration
  def change
    create_table :user_menus do |t|
      t.belongs_to :user, :null => false
			t.belongs_to :menu, :null => false

      t.timestamps
    end

    add_index :user_menus, [:user_id]
    add_index :user_menus, [:menu_id]
    add_index :user_menus, [:user_id, :menu_id] , :unique => true
  end
end
