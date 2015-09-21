# -*- encoding : utf-8 -*-
class AddHitsToArticles < ActiveRecord::Migration
  def change
  	add_column :articles, :hits, :integer, default: 0
  	add_column :articles, :comment_user_type, :integer, default: 0, comment: "允许评论的用户类别，0不限制"
  	add_column :articles, :download_uesr_type, :integer, default: 0, comment: "允许下载附件的用户类别，0不限制" 
  	add_index :articles, :status
  	add_index :articles, :top_type
  end
end
