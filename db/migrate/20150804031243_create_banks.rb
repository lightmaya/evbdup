# -*- encoding : utf-8 -*-
class CreateBanks < ActiveRecord::Migration
  def change
    create_table :banks do |t|
      t.string :code
      t.string :name

      t.timestamps
    end
  end
end
