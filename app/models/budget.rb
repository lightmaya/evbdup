# -*- encoding : utf-8 -*-
class Budget < ActiveRecord::Base
  has_many :uploads, class_name: :BudgetUpload, foreign_key: :master_id

  belongs_to :department

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Budget") }, foreign_key: :obj_id

  scope :find_all_by_dep_code, ->(dep_real_ancestry) { where("budgets.dep_code like '#{dep_real_ancestry}/%' or budgets.dep_code = '#{dep_real_ancestry}'") }
  scope :unuse, ->{ where("budgets.status = 21")}
  
  include AboutStatus

  before_create do
    # 设置rule_id和rule_step
    init_rule
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
  end

  # 根据不同操作 改变状态
  def change_status_hash
    status_ha = self.find_step_by_rule.blank? ? 21 : 1
    return {
      "提交" => { 19 => status_ha, 0 => status_ha },
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

  def used!
    update(status: 61)
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

  def name_with_budget
    "#{self.name} [预算金额: #{self.budget}]"
  end

end
