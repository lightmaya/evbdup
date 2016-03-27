# -*- encoding : utf-8 -*-
class CreateMallTokens < ActiveRecord::Migration
  def change
    create_table :mall_tokens do |t|
      t.string :name, :comment => "名称", :null => false
      t.string :access_token, :comment => "token", :null => false
      t.datetime :due_at, :comment => "有效期", :null => false
      t.timestamps
    end
  end
end
