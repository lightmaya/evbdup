# -*- encoding : utf-8 -*-
class FaqUpload < ActiveRecord::Base
  belongs_to :master, class_name: "Faq", foreign_key: "master_id"

  has_attached_file :upload #, :styles => {thumbnail: "45x45", md: "240x180", lg: "1024x768"}
  validates_attachment_content_type :upload, :content_type => ['image/jpeg', 'image/jpg', 'image/png','image/pjpeg','image/x-png','application/msword','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/msexcel','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','application/pdf','application/octet-stream','application/zip'], :message => "文件格式有误"
  # before_post_process :allow_only_images

  include Rails.application.routes.url_helpers
  include UploadFiles

  # 上传附件的提示 -- 需要跟下面的JS设置匹配
  def self.tips
    '<ol>
      <li>仅支持jpg、jpeg、png、pdf、doc、xls、rar、zip等格式的文件；</li>
      <li>单个文件大小不能超过8M；</li>
      <li>上传文件的数量不超过10个。</li>
    </ol>'
  end

  # 上传附件的JS设置 -- 需要跟上面的Tips匹配；注意：必须用单引号，避免正则表达式转义
  def self.jquery_setting
    '{
      autoUpload: true,
      acceptFileTypes: /(\.|\/)(jpe?g|png|pdf|doc|xls|docx|xlsx|rar|zip)$/i,
      maxNumberOfFiles: 10,
      maxFileSize: 8388600
    }'
  end

end
