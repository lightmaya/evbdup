class AddBudgetIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :budget_id, :integer
    add_index :orders, :budget_id
    rename_column :orders, :budget, :budget_money
  end
end
