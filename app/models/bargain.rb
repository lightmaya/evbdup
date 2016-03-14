# -*- encoding : utf-8 -*-
class Bargain < ActiveRecord::Base
  has_many :uploads, class_name: :BargainUpload, foreign_key: :master_id
  has_many :products, class_name: :BargainProduct
  has_many :bids, class_name: :BargainBid
  # default_scope -> {order("id desc")}
  belongs_to :item
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
    #  ["暂存", 0, "orange", 10], ["结果审核拒绝", 21, "purple", 50],
    #  ["结果等待审核", 22, "sea", 60], ["确定中标人", 23, "u", 100],
    #  ["已删除", 404, "dark", 100], ["已作废", 47, "dark", 100],
    #  ["等待报价", 17, "brown", 30], ["等待确认报价结果", 18, "light-green", 50]
    # ]
    self.get_status_array(["暂存", "等待报价", "确定中标人", "等待确认报价结果", "已作废", "结果等待审核", "结果审核拒绝", "已删除"])
  end

  def self.confirm_status
    18
  end

  # 根据品目判断审核人 插入待办事项用
  def audit_user_ids
    self.category.user_ids.flatten.uniq
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    case act
    when "show"
      current_u.real_department.is_ancestors?(self.department_id)
    when "update", "edit", "choose", "update_choose"
      self.class.edit_status.include?(self.status) && current_u.try(:id) == self.user_id
    when "commit"
      self.can_opt?("提交") && current_u.try(:id) == self.user_id && self.bids.present?
    when "update_audit", "audit"
      self.class.audit_status.include?(self.status)
    when "delete", "destroy"
      self.can_opt?("删除") && current_u.try(:id) == self.user_id
    when "bid", "update_bid"
      self.can_bid? && self.bids.find_by(department_id: current_u.department.id).present?
    when "confirm", "update_confirm"
      self.status == 18 && current_u.try(:id) == self.user_id
    else false
    end
  end

  # 可以报价
  def can_bid?
    self.status == 17
  end

  # 流程图的开始数组
  def step_array
    arr = ["发起议价", "选择报价供应商"]
    arr |= self.get_obj_step_names
    return arr
  end

  def self.xml(act='')
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='采购单位' column='dep_name' class='required' display='readonly'/>
        <node name='发票抬头' column='invoice_title' />
        <node name='联系人' column='dep_man' class='required'/>
        <node name='联系人座机' column='dep_tel' class='required'/>
        <node name='联系人手机' column='dep_mobile' class='required'/>
        <node name='联系人地址' column='dep_addr' class='required' />
        #{"<node name='预算金额（元）' column='total' class='number required box_radio' json_url='/kobe/shared/get_budgets_json' partner='budget_id' hint='如果没有可选项，请先填写预算审批单'/>
          <node column='budget_id' data_type='hidden'/>" unless act == "bid"}
        <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
      </root>
    }
  end

  def self.confirm_xml(act='')
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='操作理由' class='required' data_type='textarea' placeholder='不超过800字'/>
        <node name='bid_id' data_type='hidden'/>
      </root>
    }
  end

  # 选择供应商的提示信息
  def self.tips
    msg = []
    msg << "A级供应商默认全部选中"
    msg << "不足三家供应商，请选择其他的产品参数或其他的采购方式"
  end

  # 没有选择A级供应商的提示
  def self.a_dep_tips
    "你选择的供应商中不包括全部的A级供应商，请重新选择报价供应商！"
  end

  # 报价时不显示报价日志
  def show_logs
    if self.can_bid?
      doc = Nokogiri::XML(self.logs)
      # note = doc.search("/root/node[(@操作内容='报价')]") # find all tags with the node_name "note"
      note = doc.search("/root/node[(@操作内容='报价')] | /root/node[(@操作内容='修改报价')]")
      note.remove
      doc
    else
      Nokogiri::XML(self.logs)
    end
  end

  # 中标报价
  def bid_success
    self.bids.find_by(is_bid: true)
  end

end
