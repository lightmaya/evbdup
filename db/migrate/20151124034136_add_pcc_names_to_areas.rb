class AddPccNamesToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :pcc_name, :string
    add_column :areas, :pcc_ids, :string
  end
end
