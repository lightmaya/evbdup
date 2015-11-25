class AddHtTemplateToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :ht_template, :string
    add_column :orders, :comment_total, :integer
    add_column :orders, :comment_detail, :text

    change_column :orders, :other_fee_desc, :text

    add_column :orders_items, :comment_detail, :text
    add_column :orders_items, :old_id, :integer
    add_column :orders_items, :old_table, :string

    add_index :orders_items, [:old_id, :old_table]
  end
end
