# -*- encoding : utf-8 -*-
class CreateArticleCatalogs < ActiveRecord::Migration
  def change
    create_table :article_catalogs do |t|
    	t.string :title, :null => false
      t.integer :status, :limit => 2
      t.text :details
      t.text :logs
      t.float :sort
      t.string :rule_step
      t.integer :rule_id
      t.string :ancestry
      t.integer :ancestry_depth
      t.timestamps
    end

    add_column :articles, :username, :string
    add_column :articles, :logs, :text
    add_column :articles, :content, :text, :limit => 4294967295
  end
end
