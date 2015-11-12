# -*- encoding : utf-8 -*-
class Budget < ActiveRecord::Base
  has_many :uploads, class_name: :BudgetUpload, foreign_key: :master_id

  belongs_to :order
  belongs_to :department

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Plan") }, foreign_key: :obj_id

  scope :find_all_by_dep_code, ->(dep_real_ancestry) { where("dep_code like '#{dep_real_ancestry}/%' or dep_code = '#{dep_real_ancestry}'") }

  include AboutStatus

  before_create do
    # 设置rule_id
    self.rule_id = Rule.find_by(yw_type: self.class.to_s).try(:id)
    self.rule_step = 'start'
  end

  # 附件的类
  def self.upload_model
    BudgetUpload
  end

  # 中文意思 状态值 标签颜色 进度 
  def self.status_array
    [
      ["未提交",0,"orange",10],
      ["未使用",21,"u",100],
      ["已使用",61,"u",100],
      ["等待审核",1,"blue",50],
      ["审核拒绝",19,"red",0],
      ["已删除",404,"light",0]
    ]
    # [["未提交", 5, "orange", 10], ["审核通过", 21, "u", 100], ["等待审核", 1, "blue", 50], ["审核拒绝", 19, "red", 0], ["已删除", 404, "red", 0]]
    # get_status_array(["未提交", "审核通过", "等待审核", "审核拒绝", "已删除"])
  end

  # 根据不同操作 改变状态
  def change_status_hash
    {
      "提交" => { 0 => 1, 19 => 1 },
      "通过" => { 1 => 21 },
      "不通过" => { 1 => 19 },
      "删除" => { 0 => 404 }
    }
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    case act
    when "show" 
      current_u.department.is_ancestors?(self.department_id)
    when "update", "edit" 
      [0,3].include?(self.status) && current_u.try(:id) == self.user_id
    when "commit" 
      self.can_opt?("提交") && current_u.try(:id) == self.user_id
    when "update_audit", "audit" 
      self.can_opt?("通过") && self.can_opt?("不通过")
    when "delete", "destroy" 
      self.can_opt?("删除") && current_u.try(:id) == self.user_id
    else false
    end
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='预算审批单名称' column='name' class='required' hint='例如：****2015年输送机预算审批单'/>
        <node name='总预算金额（元）' column='budget' class='required number'/>
        <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
      </root>
    }
  end

end
