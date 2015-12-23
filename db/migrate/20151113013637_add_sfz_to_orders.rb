# -*- encoding : utf-8 -*-
class AddSfzToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :sfz, :string
  end
end
