# -*- encoding : utf-8 -*-
class Budget < ActiveRecord::Base
  has_many :uploads, class_name: :BudgetUpload, foreign_key: :master_id

  belongs_to :department

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Budget") }, foreign_key: :obj_id

  scope :find_all_by_dep_code, ->(dep_real_ancestry) { where("budgets.dep_code like '#{dep_real_ancestry}/%' or budgets.dep_code = '#{dep_real_ancestry}'") }
  scope :unuse, ->{ where("budgets.status = 51")}

  include AboutStatus

  default_value_for :status, 0

  before_create do
    # 设置rule_id和rule_step
    init_rule
  end

  after_save do
    # 如果是已经使用的预算审批单 需要修改预算 保存之后更新对应的网上竞价或协议议价
    if self.status == 19
      obj = BidProject.find_by(budget_id: self.id)
      if obj.present?
        obj.update budget_money: self.total
      else
        obj = Bargain.find_by(budget_id: self.id)
        obj.update(total: self.total) if obj.present?
      end
    end
  end

  # 附件的类
  def self.upload_model
    BudgetUpload
  end

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [
    #   ["暂存", "0", "orange", 10],
    #   ["未使用", "51", "yellow", 100],
    #   ["已使用", "19", "dark", 100],
    #   ["等待审核", "8", "blue", 60],
    #   ["审核拒绝", "7", "red", 20],
    #   ["已删除", "404", "dark", 100]
    # ]
    self.get_status_array(["暂存", "未使用", "已使用", "等待审核", "审核拒绝", "已删除"])
    # [
    #   ["未提交",0,"orange",10],
    #   ["未使用",21,"u",100],
    #   ["已使用",61,"u",100],
    #   ["等待审核",1,"blue",50],
    #   ["审核拒绝",19,"red",0],
    #   ["已删除",404,"light",0]
    # ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   status_ha = self.find_step_by_rule.blank? ? 21 : 1
  #   return {
  #     "提交" => { 19 => status_ha, 0 => status_ha },
  #     "通过" => { 1 => 21 },
  #     "不通过" => { 1 => 19 },
  #     "删除" => { 0 => 404 }
  #   }
  # end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    case act
    when "show"
      current_u.real_department.is_ancestors?(self.department_id)
    when "update", "edit"
      (self.class.edit_status.include?(self.status) || self.order.blank?) && current_u.try(:id) == self.user_id
    when "commit"
      self.can_opt?("提交") && current_u.try(:id) == self.user_id && self.total != 0
    when "update_audit", "audit"
      self.class.audit_status.include?(self.status)
    when "delete", "destroy"
      self.can_opt?("删除") && current_u.try(:id) == self.user_id
    else false
    end
  end

  # 对应的订单
  def order
    Order.find_by(budget_id: self.id)
  end

  def used!
    update(status: 19) unless self.status == 19
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='预算审批单名称' column='name' class='required' hint='例如：****2015年输送机预算审批单'/>
        <node name='总预算金额（元）' column='total' class='required number'/>
        <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
      </root>
    }
  end

  def name_with_budget
    "#{self.name} [预算金额: #{self.total}]"
  end

end
