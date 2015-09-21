# -*- encoding : utf-8 -*-
class CreateMsgs < ActiveRecord::Migration
  def change
    create_table :msgs do |t|
    	t.string :title, :comment => "标题"
    	t.text :content, :comment => "内容"
      t.integer :user_id, :comment => "写信人id"
      t.string :user_name, :comment => "写信人"
      t.text :logs, :comment => "日志"
      t.integer :send_type, :limit => 2, :comment => "接受人群"
      t.text :send_tos, :comment => "具体接收人"
      t.integer :status
      t.timestamps
    end

    add_index :msgs, :user_id

    create_table :msg_users do |t|
      t.integer :user_id, :comment => "接受人", :null => false
      t.integer :msg_id, :comment => "短消息id", :null => false
      t.boolean :is_read, :default => 0 
      t.timestamps
    end

    add_index :msg_users, :msg_id
    add_index :msg_users, :is_read
    add_index :msg_users, :user_id
    add_index :msg_users, [:user_id, :msg_id], :unique => true
  end
end
