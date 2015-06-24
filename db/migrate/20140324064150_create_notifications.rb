# -*- encoding : utf-8 -*-
class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
    t.integer :sender_id, :comment => "发送者ID", :null => false
	  t.integer :receiver_id, :comment => "接收者ID", :null => false
	  t.integer :category , :comment => "类别ID", :null => false
	  t.string :title, :comment => "标题"
	  t.string :content, :comment => "内容"
    t.integer :status, :comment => "状态", :limit => 2, :default => 0 ,:null => false

    t.timestamps
    end
    add_index :notifications, :sender_id
    add_index :notifications, :receiver_id
  end
end
