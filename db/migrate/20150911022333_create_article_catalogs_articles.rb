class CreateArticleCatalogsArticles < ActiveRecord::Migration
  def change
    create_table :article_catalogs_articles, id: false do |t|
    	t.integer :article_id, :null => true
    	t.integer :article_catalog_id, :null => true
    end

    add_index :article_catalogs_articles, [:article_id, :article_catalog_id], :unique => true, :name => 'my_index'
  	add_index :article_catalogs_articles, :article_id
  	add_index :article_catalogs_articles, :article_catalog_id 
  end
end
