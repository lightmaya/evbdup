class ChangeEndTimeForItems < ActiveRecord::Migration
  def change
    change_column :items, :begin_time, :datetime
    change_column :items, :end_time, :datetime
  end
end
