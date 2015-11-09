# -*- encoding : utf-8 -*-
class Article < ActiveRecord::Base
  # 模型名称
  Mname = "文章"

	belongs_to :author, class_name: "User", foreign_key: "user_id"
  has_many :uploads
	has_and_belongs_to_many :catalogs, class_name: "ArticleCatalog"
	accepts_nested_attributes_for :catalogs
  has_many :task_queues, -> { where(class_name: "Article") }, foreign_key: :obj_id
  
  default_value_for :hits, 0
  default_value_for :status, 0

  scope :published, -> { where(status: 1) }

  ####### status及审核相关 ############
  # 有status字段的需要加载AboutStatus
  include AboutStatus  

  

  # 根据action_name 判断obj有没有操作
  # 用于前台的操作按钮，在BtnArrayHelper.rb中配置，与cancancan结合使用
  def cando(act='')
    case act
    when "commit" 
      # 必须是0状态并且没有数据合法才能commit
      [0].include?(self.status) && self.get_tips.blank?
    when "update_audit", "audit" 
      # change_status_hash中是否有此操作
      self.can_opt?("通过") && self.can_opt?("不通过")
    else false
    end
  end

  # 获取提示信息 用于1.注册完成时提交的提示信息、2.登录后验证个人信息是否完整
  def get_tips
    msg = []
    if [0].include?(self.status)
      msg << "请填写内容" if self.content.blank?
      msg << "请填写标题" if self.title.blank?
    end
    return msg
  end

  ####### status及审核相关 END ############

  # 审核流程必须有rule
  belongs_to :rule
  def commit_params
    arr = []
    rule_id = Rule.find_by(yw_type: self.class.to_s).try(:id)
    arr << "rule_id = #{rule_id}"
    # 起始状态
    arr << "rule_step = 'start'"
    return arr
  end

  # 定义form表单
  # name: label名称
  # column: 对应字段
  # class: 样式及效验. [required]必须填写
  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='公告标题' column='title' class='required'/>
        <node name='置顶' column='top_type' class='required'  data='#{Dictionary.top_type}'  data_type='select'/>
        <node name='几天内显示新' column='new_days' class='required number' hint='请填写自然数' />
        <node name='发布人' column='username' class='required' />
        <node name='内容' column='content' data_type='richtext' style='width:100%;height:300px;' />
        <node name='公告目录' class='tree_checkbox' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"ArticleCatalog"}' partner='catalog_ids'/>
        <node column='catalog_ids' data_type='hidden'/>
      </root>
    }
  end


  def incr_hit!
    update(hits: self.hits + 1)
  end
end
