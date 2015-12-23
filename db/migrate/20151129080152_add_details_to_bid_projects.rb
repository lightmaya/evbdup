# -*- encoding : utf-8 -*-
class AddDetailsToBidProjects < ActiveRecord::Migration
  def change
    add_column :bid_projects, :details, :text

    remove_column :bid_projects, :buy_type, :integer
    remove_column :bid_projects, :top_dep_name, :string
    remove_column :bid_projects, :buyer_email, :string

    remove_column :bid_items, :logs, :text

    add_column :bid_project_bids , :bid_time, :datetime
    add_column :bid_project_bids , :department_id, :integer
    add_column :bid_project_bids , :is_bid, :integer

  end
end
