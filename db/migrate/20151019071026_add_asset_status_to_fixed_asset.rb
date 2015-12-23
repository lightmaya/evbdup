# -*- encoding : utf-8 -*-
class AddAssetStatusToFixedAsset < ActiveRecord::Migration
  def change
    add_column :fixed_assets, :asset_status, :integer,:comment => "车辆状态"
  end
end
