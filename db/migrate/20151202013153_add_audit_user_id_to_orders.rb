class AddAuditUserIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :audit_user_id, :integer

    add_column :orders, :mall_id, :integer
  end
end
