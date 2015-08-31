class AddCodeToRules < ActiveRecord::Migration
  def change
    add_column :rules, :code, :string
    add_column :rules, :yw_type, :string

    add_column :orders, :yw_type, :string
  end
end
