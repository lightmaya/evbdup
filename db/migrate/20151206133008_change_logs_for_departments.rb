# -*- encoding : utf-8 -*-
class ChangeLogsForDepartments < ActiveRecord::Migration
  def change

    change_column :departments, :logs, :text, :limit => 4294967295

    change_column :users, :logs, :text, :limit => 4294967295
    
    change_column :menus, :logs, :text, :limit => 4294967295
    
    change_column :categories, :logs, :text, :limit => 4294967295
    
    change_column :orders, :logs, :text, :limit => 4294967295
    
    change_column :products, :logs, :text, :limit => 4294967295
    
    change_column :rules, :logs, :text, :limit => 4294967295
    
    change_column :to_do_lists, :logs, :text, :limit => 4294967295
    
    change_column :items, :logs, :text, :limit => 4294967295
    
    change_column :article_catalogs, :logs, :text, :limit => 4294967295
    
    change_column :articles, :logs, :text, :limit => 4294967295
    
    change_column :agents, :logs, :text, :limit => 4294967295
    
    change_column :msgs, :logs, :text, :limit => 4294967295
    
    change_column :coordinators, :logs, :text, :limit => 4294967295
    
    change_column :bid_projects, :logs, :text, :limit => 4294967295
    
    change_column :plan_items, :logs, :text, :limit => 4294967295
    
    change_column :plans, :logs, :text, :limit => 4294967295
    
    change_column :daily_categories, :logs, :text, :limit => 4294967295
    
    change_column :daily_costs, :logs, :text, :limit => 4294967295
    
    change_column :fixed_assets, :logs, :text, :limit => 4294967295
    
    change_column :asset_projects, :logs, :text, :limit => 4294967295
    
    change_column :faqs, :logs, :text, :limit => 4294967295
    
    change_column :budgets, :logs, :text, :limit => 4294967295
    
    change_column :transfers, :logs, :text, :limit => 4294967295
  
  end
end
