# -*- encoding : utf-8 -*-
class CreateDepartmentsUploads < ActiveRecord::Migration
  def change
    create_table :departments_uploads do |t|
    	t.belongs_to :master, :default => 0
      t.string   "upload_file_name"   , :comment => "文件名称"
      t.string   "upload_content_type", :comment => "文件类型"
      t.integer  "upload_file_size"   , :comment => "文件大小"
      t.datetime "upload_updated_at"  , :comment => "时间戳"
      t.timestamps
    end
    add_index :departments_uploads, [:master_id]
  end
end
