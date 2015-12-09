class AddIndexToOrders < ActiveRecord::Migration
  def change

    add_index :orders, :rule_id
    add_index :orders, :buyer_id
    add_index :orders, :buyer_code
    add_index :orders, :seller_id
    add_index :orders, :seller_name
    add_index :orders, :yw_type
    add_index :orders, :status
    add_index :orders, :contract_sn
    
    add_index :departments, :real_ancestry
  end
end
