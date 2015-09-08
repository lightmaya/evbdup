# -*- encoding : utf-8 -*-
class CreateSuggestion < ActiveRecord::Migration
  def change
    create_table :suggestions do |t|
    	t.text :content, :null => false, :comment => "意见反馈"
      t.string :email, :comment => "电子邮箱"
      t.string :mobile, :comment => "手机"
      t.string :QQ, :comment => "QQ号"
      t.integer :status, :null => false, :limit => 2, :default => 0, :comment => "状态"
      t.text :logs , :comment => "日志"
      t.integer :user_id, :comment => "用户ID"

      t.timestamps
    end
  end
end
