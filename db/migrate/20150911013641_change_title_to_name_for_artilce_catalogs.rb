class ChangeTitleToNameForArtilceCatalogs < ActiveRecord::Migration
  def change
  	rename_column :article_catalogs, :title, :name 
  	remove_column :article_catalogs, :rule_id
  	remove_column :article_catalogs, :rule_step
  	add_column :article_catalogs, :catalog_ids, :string, default: ""
  	
  end
end
