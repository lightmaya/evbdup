class AddItemIdToOrdersItems < ActiveRecord::Migration
  def change
  	add_column :orders_items, :item_id, :integer
  end
end
