class CreateUserCategories < ActiveRecord::Migration
  def change
    create_table :user_categories do |t|
    	t.belongs_to :user, :null => false
			t.belongs_to :category, :null => false

      t.timestamps
    end

    add_index :user_categories, [:user_id]
    add_index :user_categories, [:category_id]
    add_index :user_categories, [:user_id, :category_id] , :unique => true
  end
end
