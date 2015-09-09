# -*- encoding : utf-8 -*-
class CreateUploads < ActiveRecord::Migration
  def change
    create_table :uploads do |t|
      t.integer  "master_id"
      t.string  "master_type"
      t.string   "upload_file_name"   , :comment => "文件名称"
      t.string   "upload_content_type", :comment => "文件类型"
      t.integer  "upload_file_size"   , :comment => "文件大小"
      t.datetime "upload_updated_at"  , :comment => "时间戳"
      t.timestamps
    end

    add_index :uploads, [:master_id, :master_type]
  end
end
