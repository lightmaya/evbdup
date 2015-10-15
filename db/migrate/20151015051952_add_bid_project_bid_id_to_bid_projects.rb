# -*- encoding : utf-8 -*-
class AddBidProjectBidIdToBidProjects < ActiveRecord::Migration
  def change
  	add_column :bid_projects, :bid_project_bid_id, :integer, :comment => "中标投标ID"
  	add_column :bid_projects, :reason, :text, :comment => "理由"
  	add_index :bid_projects, :bid_project_bid_id
  end

end
