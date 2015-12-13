class AddIndexToMenus < ActiveRecord::Migration
  def change
    add_column :items, :user_id, :integer

    add_index :menus, :route_path
    add_index :menus, :user_type

  end
end
