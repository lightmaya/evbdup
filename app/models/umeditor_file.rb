# -*- encoding : utf-8 -*-
class UmeditorFile < ActiveRecord::Base
	mount_uploader :data, ImageUploader, :mount_on => :store_name

  validates :data, :presence => true

  before_save :update_asset_attributes

  protected

  def update_asset_attributes
    self.content_type ||= data.file.content_type
    self.file_size ||= data.file.size
  end

end
