# -*- encoding : utf-8 -*-
class CreateUmeditorFiles < ActiveRecord::Migration
  def change
    create_table :umeditor_files do |t|
      t.string :original_name, :comment => "原始名称"
      t.string :store_name, :null => false, :comment => "保存名称"
      t.integer :file_size, :comment => "文件大小"
      t.string :content_type, :comment => "文件类型"
      t.string :description, :comment => "文件描述"
      t.integer :user_id
      t.timestamps
    end

    add_index :umeditor_files, :user_id
  end
end

