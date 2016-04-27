# -*- encoding : utf-8 -*-
class CreateOtherUploads < ActiveRecord::Migration
  def change
    create_table :other_uploads do |t|
      t.belongs_to :master, :default => 0
      t.string "yw_type", :comment => "业务类型"
      t.string   "upload_file_name"   , :comment => "文件名称"
      t.string   "upload_content_type", :comment => "文件类型"
      t.integer  "upload_file_size"   , :comment => "文件大小"
      t.datetime "upload_updated_at"  , :comment => "时间戳"
      t.timestamps
    end
    add_index :other_uploads, [:master_id, :yw_type]
  end
end
