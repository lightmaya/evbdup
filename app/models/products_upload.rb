# -*- encoding : utf-8 -*-
class ProductsUpload < ActiveRecord::Base
	belongs_to :master, class_name: "Product", foreign_key: "master_id"

  has_attached_file :upload, :styles => {thumbnail: "45x45", md: "240x180#", lg: "1024x768#"}
  validates_attachment_content_type :upload, :content_type => /\Aimage\/.*\Z/, :message => "只能上传图片文件" 
  before_post_process :allow_only_images

	include Rails.application.routes.url_helpers
  include UploadFiles

  # 上传附件的提示 -- 需要跟下面的JS设置匹配
  def self.tips
    '<ol>
      <li>仅支持jpg、jpeg、png、gif等格式的图片文件；</li>
      <li>单个文件大小不能超过1M；</li>
      <li>上传文件个数不超过10个。</li>
    </ol>'
  end

  # 上传附件的JS设置 -- 需要跟上面的Tips匹配；注意：必须用单引号，避免正则表达式转义
  def self.jquery_setting
    '{
      autoUpload: true,
      acceptFileTypes: /(\.|\/)(gif|jpe?g|png)$/i,
      maxNumberOfFiles: 10,
      maxFileSize: 1024000
    }'
  end
end
