class AddUserTypeToMenus < ActiveRecord::Migration
  def change
    add_column :menus, :user_type, :string
    
    remove_column :budgets, :order_id, :integer

    rename_column :users, :user_type, :is_personal
    
  end
end
