class AddAgentIdToOrderItems < ActiveRecord::Migration
  def change
    add_column :orders_items, :agent_id, :integer
  end
end
