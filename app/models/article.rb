# -*- encoding : utf-8 -*-
class Article < ActiveRecord::Base
	belongs_to :author, class_name: "User", foreign_key: "user_id"
  has_many :uploads
	has_and_belongs_to_many :categories, class_name: "ArticleCatalog"
	accepts_nested_attributes_for :categories
  scope :published, -> { where(status: 1) }

  include AboutStatus

   # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	limited = [404]
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  # 中文意思 状态值 标签颜色 进度 
	def self.status_array
		[
	    ["暂存", 0, "orange", 50],
      ["提交审核", 1, "orange", 90],
	    ["已发布", 2, "u", 100],
	    ["已删除", 404, "red", 0]
    ]
  end

   def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='公告标题' column='title' class='required'/>
        <node name='置顶' column='top_type' class='required'  data='#{Dictionary.top_type}'  data_type='select'/>
        <node name='几天内显示新' column='new_days' class='required number' hint='请填写自然数' />
        <node name='发布人' column='username' class='required' />
        <node name='内容' column='content' class='required' data_type='richtext' style='width:100%;height:300px;' />
        <node name='状态' column='status' data_type='radio' data='[[0, "暂存"],[1, "提交审核"]]'/>
      </root>
    }
  end

end
