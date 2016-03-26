# -*- encoding : utf-8 -*-
class ChangeLogsForBargains < ActiveRecord::Migration
  def change

    change_column :bargains, :logs, :text, :limit => 4294967295

    change_column :bargain_bids, :logs, :text, :limit => 4294967295

  end
end
