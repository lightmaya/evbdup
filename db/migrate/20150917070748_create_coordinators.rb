# -*- encoding : utf-8 -*-
class CreateCoordinators < ActiveRecord::Migration
  def change
    create_table :coordinators do |t|
      t.belongs_to :item, :default => 0, :comment => "项目ID", :null => false
      t.belongs_to :department, :default => 0, :comment => "单位ID", :null => false
      t.string :name, :comment => "姓名"
      t.string :tel, :comment => "电话"
      t.string :mobile, :comment => "手机"
      t.string :fax, :comment => "传真"
      t.string :email, :comment => "Email"
      t.integer :status, :comment => "状态", :limit => 2, :default => 0,:null => false
      t.text :summary, :comment => "备注"
      t.text :details, :comment => "明细"
      t.belongs_to :user, :default => 0, :comment => "用户ID", :null => false
      t.text :logs, :comment => "日志"

      t.timestamps
    end
  end
end
