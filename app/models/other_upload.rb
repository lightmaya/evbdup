# -*- encoding : utf-8 -*-
class OtherUpload < ActiveRecord::Base

  has_attached_file :upload, :styles => {thumbnail: "45x45", md: "240x180", lg: "1024x768"}
  validates_attachment_content_type :upload, :content_type => ['image/jpeg', 'image/jpg', 'image/png','image/pjpeg','image/x-png','application/pdf'], :message => "文件格式有误"
  # before_post_process :allow_only_images

  include Rails.application.routes.url_helpers
  include UploadFiles

  # 上传附件的提示 -- 需要跟下面的JS设置匹配
  def self.tips
    '<ol>
      <li>仅支持jpg、jpeg、png、pdf等格式的文件；</li>
      <li>单个文件大小不能超过2M；</li>
      <li>上传文件的数量不超过10个。</li>
    </ol>'
  end

  # 上传附件的JS设置 -- 需要跟上面的Tips匹配；注意：必须用单引号，避免正则表达式转义
  def self.jquery_setting
    '{
      autoUpload: true,
      acceptFileTypes: /(\.|\/)(jpe?g|png|pdf)$/i,
      maxNumberOfFiles: 10,
      maxFileSize: 2097152
    }'
  end

  # 重写UploadFiles中的to_jq_upload
  def to_jq_upload
    {
      "id" => read_attribute(:id),
      "name" => read_attribute(:upload_file_name),
      "size" => read_attribute(:upload_file_size),
      "url" => upload.url(:original),
      "thumbnail_url" => (upload_content_type.index("image/") ? upload.url(:thumbnail) : get_uploaded_file_icon(read_attribute(:upload_file_name))),
      "delete_url" => upload_path(self, upload_model: self.class.to_s, master_id:self.master_id, upload_master_model: self.yw_type),
      "delete_type" => "DELETE"
    }
  end
end
