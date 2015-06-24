# -*- encoding : utf-8 -*-
class Suggestion < ActiveRecord::Base
  has_many :uploads, class_name: :SuggestionsUpload, foreign_key: :master_id
	include AboutStatus

  # 附件的类
  def self.upload_model
    SuggestionsUpload
  end
  
	def self.xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	      <node name='邮箱地址' column='email' rules='{email:true}' placeholder='建议留下常用的邮箱，便于我们及时回复您'/>
	      <node name='QQ号码' column='QQ' rules='{digits:true}' messages='请输入正确的QQ号码' placeholder='建议留下常用的QQ号码，便于我们及时回复您'/>
	      <node name='手机号码' column='mobile' rules='{digits:true}' messages='请输入正确的手机号码' placeholder='建议留下常用的手机号码，便于我们及时回复您'/>
	      <node name='意见反馈' column='content' data_type='textarea' placeholder='请直接填写您遇到的问题或意见建议，您的意见对是我们前进的动力（800字以内）。' rules='{required:true, maxlength:800}' messages='800字以内'/>
	    </root>
	  }
	end

	# 中文意思 状态值 标签颜色 进度 
	def self.status_array
		[
	    ["未读",0,"orange",10,[1,4,101],[1,0]],
	    ["已读",1,"blue",50,[0,4],[3,4]],
	    ["已处理",3,"u",100,[1,4],[3,4]],
	    ["不需处理",4,"purple",100,[0,1,101],[3,4]],
	    ["已删除",404,"red",100,[0,1,3,4],nil]
    ]
  end

	# 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	limited = [404]
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  def cando_list(action='')
    arr = [] 
    # 查看详细
    if [0,1,2,3,4,404].include?(self.status)
    	arr << [self.class.icon_action("详细"), "/kobe/suggestions/#{self.id}", target: "_blank"]
   	end
    # 标记为已读
    if [0,4,404].include?(self.status)
    	arr << [self.class.icon_action("标记为已读"), "/kobe/suggestions/#{self.id}/mark_as_read", method: :post]
    end
    # 标记为未读
    if [1,404].include?(self.status)
    	arr << [self.class.icon_action("标记为未读"), "/kobe/suggestions/#{self.id}/mark_as_unread", method: :post]
    end
    # 删除
    if [0,1,3,4].include?(self.status)
	    arr << [self.class.icon_action("删除"), "/kobe/suggestions/#{self.id}", method: :delete, data: {confirm: "确定要删除吗?"}]
	  end
    # 彻底删除
    if self.status == 404
	    arr << [self.class.icon_action("彻底删除"), "/kobe/suggestions/#{self.id}", method: :delete, data: {confirm: "删除后不可恢复，确定要删除吗?"}]
	  end
	  return arr
  end



end
