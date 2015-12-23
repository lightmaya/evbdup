# -*- encoding : utf-8 -*-
class CreateFaqs < ActiveRecord::Migration
  def change
    create_table :faqs do |t|
    	t.string :catalog ,:comment =>"分类信息"
			t.text :title, :comment => "标题/问题"
			t.text :content , :comment => "内容/答案"
      t.integer :sort , :comment =>"排序"
      t.integer :ask_user_id,  :comment => "提问者ID"
      t.string  :ask_user_name, :comment => "提问者名字"
      t.string  :ask_dep_name,   :comment => "提问者单位"
      t.belongs_to :user , :comment => "自己发布自己回答ID", :null => false, :default => 0
    	t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
    	t.text :details                  , :comment => "明细"
    	t.text :logs                     , :comment => "日志"

      t.timestamps
    end
    create_table :faq_uploads do |t|
    	t.belongs_to :master, :default => 0
      t.string   "upload_file_name"   , :comment => "文件名称"
      t.string   "upload_content_type", :comment => "文件类型"
      t.integer  "upload_file_size"   , :comment => "文件大小"
      t.datetime "upload_updated_at"  , :comment => "时间戳"

      t.timestamps
    end

    add_index :faq_uploads, [:master_id]

  end
end
