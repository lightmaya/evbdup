class AddAreaIdToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :area_id, :integer
  end
end
