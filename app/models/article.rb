# -*- encoding : utf-8 -*-
class Article < ActiveRecord::Base
	belongs_to :author, class_name: "User", foreign_key: "user_id"
  has_many :uploads
	has_and_belongs_to_many :catalogs, class_name: "ArticleCatalog"
	accepts_nested_attributes_for :catalogs
  has_many :task_queues, -> { where(class_name: "Article") }, foreign_key: :obj_id
  belongs_to :rule

  include AboutStatus

  default_value_for :hits, 0
  default_value_for :status, 0

  scope :published, -> { where(status: 1) }

   # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	# limited = [404]
    limited = []
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  # 中文意思 状态值 标签颜色 进度 
	def self.status_array
		[
	    ["暂存", 0, "orange", 50],
      ["等待审核", 1, "orange", 90],
	    ["已发布", 2, "u", 100],
      ["审核拒绝",3,"red",0],
	    ["已删除", 404, "red", 0]
    ]
  end

   # 根据不同操作 改变状态
  def change_status_hash
    {
      "提交审核" => { 0 => 1 },
      "删除" => { 0 => 404 },
      "通过" => { 1 => 2 },
      "不通过" => { 1 => 3 }
      # "提交审核" => { "暂存" => "等待审核" },
      # "删除" => { "暂存" => "已删除" },
      # "通过" => { "等待审核" => "已发布" },
      # "不通过" => { "等待审核" => "审核拒绝" }
    }
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='')
    case act
    when "commit" 
      [0].include?(self.status) && self.get_tips.blank?
    when "update_audit", "audit" 
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

  def commit_params
    arr = []
    # rule_id = Rule.find_by(yw_type: self.class.to_s).try(:id)
    arr << "rule_id = 3"
    arr << "rule_step = 'start'"
    return arr
  end


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
