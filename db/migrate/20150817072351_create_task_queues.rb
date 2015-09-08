# -*- encoding : utf-8 -*-
class CreateTaskQueues < ActiveRecord::Migration
  def change
    create_table :task_queues do |t|
    	t.belongs_to :to_do_list, :comment => "待办事项ID"
    	t.string :class_name, :comment => "类名", :default => "Order" , :null => false
      t.integer :obj_id, :comment => "实例ID", :default => 0 , :null => false
      t.integer :user_id, :comment => "用户ID"
      t.integer :menu_id, :comment => "菜单ID"      

      t.timestamps
    end
  end
end
