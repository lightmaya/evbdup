# -*- encoding : utf-8 -*-
class CreateArticlesCategories < ActiveRecord::Migration
  def change
    create_table :articles_categories do |t|
    	t.belongs_to :article, :null => false
    	t.belongs_to :category, :null => false
    end
    add_index :articles_categories, [:article_id, :category_id]
  end
end
