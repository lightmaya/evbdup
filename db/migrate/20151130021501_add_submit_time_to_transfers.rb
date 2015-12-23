# -*- encoding : utf-8 -*-
class AddSubmitTimeToTransfers < ActiveRecord::Migration
  def change
    add_column :transfers, :submit_time, :datetime
  end
end
