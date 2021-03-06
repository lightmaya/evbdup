# -*- encoding : utf-8 -*-
class AddOldToDepartments < ActiveRecord::Migration
  def change
    add_column :departments, :old_id, :integer
    add_column :departments, :old_table, :string

    add_column :departments, :is_secret, :boolean

    add_column :departments, :comment_total, :float

    add_index :departments, [:old_id, :old_table]
  end
end
