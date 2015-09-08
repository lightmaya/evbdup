# -*- encoding : utf-8 -*-
class AddDepIdToTaskQueues < ActiveRecord::Migration
  def change
    add_column :task_queues, :dep_id, :integer
  end
end
