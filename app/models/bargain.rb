# -*- encoding : utf-8 -*-
class Bargain < ActiveRecord::Base
  has_many :uploads, class_name: :BargainUpload, foreign_key: :master_id
  has_many :products, class_name: :BargainProduct
  # default_scope -> {order("id desc")}
  belongs_to :category
  belongs_to :department

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Bargain") }, foreign_key: :obj_id

  belongs_to :budget

  scope :find_all_by_dep_code, ->(dep_real_ancestry) { where("dep_code like '#{dep_real_ancestry}/%' or dep_code = '#{dep_real_ancestry}'") }

  include AboutStatus

  default_value_for :status, 0

  before_create do
    # 设置rule_id和rule_step
    init_rule
  end

  after_create do
    create_no(rule.code, "sn")
  end

  after_save do
    budget.try(:used!)
  end

  # 附件的类
  def self.upload_model
    BargainUpload
  end

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [
    #   ["暂存", "0", "orange", 10], ["审核通过", "9", "yellow", 70],
    #   ["等待审核", "8", "blue", 60], ["审核拒绝", "7", "red", 20],
    #   ["自动生效", "2", "yellow", 70],  ["已删除", "404", "dark", 100]
    # ]
    self.get_status_array(["暂存", "审核通过", "等待审核", "审核拒绝", "自动生效", "已删除"])
  end

  # 根据品目判断审核人 插入待办事项用
  def audit_user_ids
    self.category.user_ids.flatten.uniq
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    case act
    when "show"
      current_u.department.is_ancestors?(self.department_id)
    when "update", "edit"
      self.class.edit_status.include?(self.status) && current_u.try(:id) == self.user_id
    when "commit"
      self.can_opt?("提交") && current_u.try(:id) == self.user_id
    when "update_audit", "audit"
      self.class.audit_status.include?(self.status)
    when "delete", "destroy"
      self.can_opt?("删除") && current_u.try(:id) == self.user_id
    else false
    end
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='采购单位' column='dep_name' class='required' display='readonly'/>
        <node name='联系人' column='dep_man' class='required'/>
        <node name='联系人座机' column='dep_tel' class='required'/>
        <node name='联系人手机' column='dep_mobile' class='required'/>
        <node name='预算金额（元）' column='total' class='number required box_radio' json_url='/kobe/shared/get_budgets_json' partner='budget_id' hint='如果没有可选项，请先填写预算审批单'/>
        <node column='budget_id' data_type='hidden'/>
        <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
      </root>
    }
  end

end
