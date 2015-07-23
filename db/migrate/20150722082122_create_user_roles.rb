class CreateUserRoles < ActiveRecord::Migration
  def change
    create_table :user_roles do |t|
      t.belongs_to :user, :null => false
			t.belongs_to :role, :null => false

      t.timestamps
    end

    add_index :user_roles, [:user_id]
    add_index :user_roles, [:role_id]
    add_index :user_roles, [:user_id, :role_id] , :unique => true
  end
end
