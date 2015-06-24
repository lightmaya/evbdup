# -*- encoding : utf-8 -*-
class CreateArticles < ActiveRecord::Migration
  def change
    create_table :articles do |t|
      t.string :title, :comment => "标题"
      t.integer :user_id, :null => false, :comment => "发布者ID"
      t.datetime :publish_time, :comment => "发布时间"
      t.string :tags, :comment => "标签"
      t.integer :new_days, :null => false, :default => 3, :comment => "几天内显示new标签"
      t.integer :top_type, :null => false, :default => 0, :comment => "置顶类别"
      t.integer :access_permission, :null => false, :default => 0 , :comment => "访问权限"
      t.integer :status, :null => false, :default => 0, :comment => "状态"

      t.timestamps
    end
    add_index :articles, :title
    add_index :articles, :user_id
    add_index :articles, :tags

    create_table :article_contents do |t|
      t.integer :article_id, :null => false
      t.text :content
      t.timestamps
    end

  end
end
