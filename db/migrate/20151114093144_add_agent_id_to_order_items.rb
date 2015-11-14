class AddAgentIdToOrderItems < ActiveRecord::Migration
  def change
    add_column :order_items, :agent_id, :integer
  end
end
