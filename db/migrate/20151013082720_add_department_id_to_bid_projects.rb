# -*- encoding : utf-8 -*-
class AddDepartmentIdToBidProjects < ActiveRecord::Migration
  def change
  	add_column :bid_projects, :department_id, :integer, :comment => "单位ID"
  	add_column :bid_projects, :department_code, :string, :comment => "单位CODE"
  end
end
