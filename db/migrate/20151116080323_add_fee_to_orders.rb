# -*- encoding : utf-8 -*-
class AddFeeToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :deliver_fee, :decimal, :precision => 20, :scale => 2
    add_column :orders, :other_fee, :decimal, :precision => 20, :scale => 2
    add_column :orders, :other_fee_desc, :string
  end
end
