# -*- encoding : utf-8 -*-
class AddUserIdToItems < ActiveRecord::Migration
  def change
    add_column :items, :user_id, :integer

    add_index :agents, [:department_id, :item_id]
    add_index :agents, :item_id
    add_index :agents, :department_id
    add_index :agents, :agent_id
    add_index :agents, :user_id

    add_index :bid_projects, :rule_id

    add_index :budgets, :user_id
    add_index :budgets, :department_id

    add_index :categories, :ancestry

    add_index :coordinators, :user_id
    add_index :coordinators, [:department_id, :item_id]

    add_index :menus, :ancestry

    add_index :plans, :plan_item_id
    add_index :plans, :category_id
    add_index :plans, :category_code

    add_index :orders_items, :category_id

    add_index :products, [:department_id, :item_id]
    add_index :products, :category_id
    add_index :products, :category_code
    add_index :products, :item_id
    add_index :products, :department_id
    add_index :products, :user_id

    add_index :task_queues, [:class_name, :obj_id]
    add_index :task_queues, :user_id
    add_index :task_queues, :menu_id
    add_index :task_queues, :dep_id
    add_index :task_queues, :to_do_list_id

    add_index :users, :department_id

  end
end
