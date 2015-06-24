# -*- encoding : utf-8 -*-
class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer :department_id, :default => 0, :comment => "单位id"
      t.string :login, :comment => "登录名"
      t.string :password_digest, :null => false, :comment => "密码"
      t.string :remember_token, :comment => "自动登录"
      t.string :name, :comment => "姓名"
      t.date :birthday, :comment => "出生日期"
      t.string :portrait, :comment => "头像"
      t.string :gender, :limit => 2, :comment => "性别"
      # t.string :birthday, :limit => 10, :comment => "出生日期"
      t.string :identity_num, :comment => "身份证"
      t.string :identity_pic, :comment => "身份证图片"
      t.string :email, :comment => "电子邮箱"#, :null => false
      t.string :mobile, :comment => "手机"
      t.boolean :is_visible, :null => false, :default => true, :comment => "是否公开,目前仅指身份证和手机号"
      t.string :tel, :comment => "电话"
      t.string :fax, :comment => "传真"
      t.boolean :is_admin, :null => false, :default => false, :comment => "是否管理员"                
      t.integer :status, :null => false, :default => 0, :comment => "状态"
      t.string :duty, :comment => "职务"
      t.string :professional_title, :comment => "职称"
      t.text :bio , :comment => "个人简历"
      t.text :details , :comment => "明细"
      t.text :logs , :comment => "日志"
      t.timestamps
    end
    # add_index :users, :email,                :unique => true
    # add_index :users, :mobile,               :unique => true
    add_index :users, :login,                :unique => true
  end
end
