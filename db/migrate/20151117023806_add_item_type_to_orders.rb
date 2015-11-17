class AddItemTypeToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :item_type, :boolean
  end
end
