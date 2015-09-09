class AddDepartmentIdToProducts < ActiveRecord::Migration
  def change
    add_column :products, :department_id, :integer, :default => 0, :comment => "单位ID", :null => false
  end
end
