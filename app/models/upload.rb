# -*- encoding : utf-8 -*-
class Upload < ActiveRecord::Base

  has_attached_file :upload, :styles => {thumbnail: "45x45", md: "240x180", lg: "1024x768"}
  validates_attachment_content_type :upload, :content_type => /\Aimage\/.*\Z/, :message => "只能上传图片文件"

  validates :master_id, :presence => { message: "master_id不能为空" }
  validates :master_type, :presence => { message: "模型不能为空" }
  belongs_to :master, polymorphic: true

  before_post_process :allow_only_images

  include Rails.application.routes.url_helpers
  include UploadFiles

  # 上传附件的提示 -- 需要跟下面的JS设置匹配
  def self.tips
    '<ol>
      <li>请上传清晰有效的营业执照、组织机构代码证、税务登记证、法人身份证（正反面）扫描件；</li>
      <li>仅支持jpg、jpeg、png、gif等格式的图片文件；</li>
      <li>单个文件大小不能超过1M；</li>
      <li>上传文件个数不超过10个。</li>
    </ol>'
  end

  # 上传附件的JS设置 -- 需要跟上面的Tips匹配；注意：必须用单引号，避免正则表达式转义
  def self.jquery_setting
    '{
      autoUpload: true,
      acceptFileTypes: /(\.|\/)(gif|jpe?g|png|log)$/i,
      maxNumberOfFiles: 10,
      maxFileSize: 1024000
    }'
  end

  # 网上竞价doc、docx、xls、xlsx、ppt、pptx、jpg、png、pdf、rar、zip
  def self.bid_project_tips
    '<ol>
      <li>上传的文件仅限doc、docx、xls、xlsx、ppt、pptx、jpg、png、pdf、rar、zip格式</li>
      <li>单个文件大小不能超过10M；</li>
      <li>上传文件个数不超过5个。</li>
    </ol>'
  end

  def self.bid_project_jquery_setting
     '{
      autoUpload: true,
      acceptFileTypes: /(\.|\/)(gif|jpe?g|png|zip|rar|pdf|pptx|ppt|xlsx|xls|docx|doc)$/i,
      maxNumberOfFiles: 7,
      maxFileSize: 10240000
    }'
  end
end
