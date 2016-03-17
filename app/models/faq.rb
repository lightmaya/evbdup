# -*- encoding : utf-8 -*-
class Faq < ActiveRecord::Base

  has_many :uploads, class_name: :FaqUpload, foreign_key: :master_id

  include AboutStatus

  default_value_for :status, 0

  before_save do
    self.status = (self.catalog=='yjjy' ?  58 : 0) if self.new_record?
  end

  # 附件的类
  def self.upload_model
    FaqUpload
  end

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [
    #   ["暂存", "0", "orange", 10],
    #   ["已发布", "16", "yellow", 40],
    #   ["未回复", "58", "yellow", 80],
    #   ["已回复", "75", "dark", 100],
    #   ["已删除", "404", "dark", 100]
    # ]
    self.get_status_array(["暂存", "已发布", "未回复", "已回复", "已删除"])
		# [
	 #    ["暂存",0,"orange",50],
	 #    ["已发布",1,"u",100],
	 #    ["未回复",2,"blue",80],
	 #    ["已回复",3,"sea",100],
	 #    ["已删除",404,"light",0]
  #   ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   return {
  #     "提交" => { 0 => 1 },
  #     "删除" => { 0 => 404 },
  #     "回复" => { 2 => 3 }
  #   }
  # end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    case act
    when "show"
      true
    when "update", "edit"
      self.catalog != 'yjjy' && self.class.edit_status.include?(self.status) && current_u.try(:id) == self.user_id
    when "commit"
      self.catalog != 'yjjy' && self.can_opt?("提交") && current_u.try(:id) == self.user_id
    when "delete", "destroy"
      self.catalog != 'yjjy' && self.can_opt?("删除") && current_u.try(:id) == self.user_id
    when "reply", "update_reply"
      self.catalog == 'yjjy' && self.can_opt?("回复") && current_u.department.is_zgs?
    else false
    end
  end

  # 从表的XML加ID是为了修改的时候能找到记录
  def self.xml(catalog='')
    title = catalog == 'yjjy' ?  '建议' : '标题'
    content = catalog == 'yjjy' ? '回复' : '内容'
    if  catalog == 'yjjy'
      str = %Q{
        <node name="发布人" column="ask_user_name" display="readonly" />
        <node name="所在单位" column="ask_dep_name" display="readonly" />
      }
    end
    str = "<node name='问题类别' class='required' data_type='select' data='#{Dictionary.questions_type}' />" if catalog == "cjwt"
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        #{str}
      	<node name='#{title}' column='title' #{"data_type='textarea'" if catalog == 'yjjy'} class='required maxlength_800' />
      	#{"<node name='#{content}' column='content' data_type='textarea' class='required maxlength_800'/>" unless catalog == 'yjjy'}
      </root>
    }
  end
end
