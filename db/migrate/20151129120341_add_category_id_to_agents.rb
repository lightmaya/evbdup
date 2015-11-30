class AddCategoryIdToAgents < ActiveRecord::Migration
  def change
    add_column :agents, :category_id, :text

    add_column :bid_item_bids , :req, :text
    add_column :bid_item_bids , :remark, :text

    add_column :coordinators, :category_id, :text

  end
end
