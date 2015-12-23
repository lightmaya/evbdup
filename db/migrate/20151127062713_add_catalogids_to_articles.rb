# -*- encoding : utf-8 -*-
class AddCatalogidsToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :catalogids, :text

    remove_column :article_catalogs, :catalog_ids, :string

    add_column :articles, :details, :text

    add_column :articles, :department_id, :integer

    remove_column :articles, :comment_user_type, :integer
    remove_column :articles, :download_uesr_type, :integer
  end
end
