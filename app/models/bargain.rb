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

  # 附件的类
  def self.upload_model
    BargainUpload
  end

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [
    # ["暂存", 0, "orange", 10], ["结果审核拒绝", 21, "purple", 50], ["废标审核拒绝", 28, "purple", 50],
    # ["结果等待审核", 22, "sea", 60], ["废标等待审核", 29, "sea", 60], ["已成交", 23, "u", 100], ["已删除", 404, "dark", 100],
    # ["已作废", 47, "dark", 100], ["等待报价", 17, "brown", 30], ["等待选择成交人", 18, "light-green", 50]
    # ]
    self.get_status_array(["暂存", "等待报价", "已成交", "等待选择成交人", "已作废", "结果等待审核", "结果审核拒绝", "已删除", "废标等待审核", "废标审核拒绝"])
  end

  # 等待选择成交人的状态
  def self.confirm_status
    18
  end

  # 可以显示报价信息
  def show_bids?
    status >= Bargain.confirm_status
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
      self.can_opt?("提交") && current_u.try(:id) == self.user_id && self.bids.present?  && self.total != 0
    when "update_audit", "audit"
      self.class.audit_status.include?(self.status)
    when "delete", "destroy"
      self.can_opt?("删除") && current_u.try(:id) == self.user_id
    when "bid", "update_bid"
      self.can_bid? && self.bids.find_by(department_id: current_u.real_department.id).present?
    when "confirm", "update_confirm"
      Bargain.buyer_edit_status.include?(self.status) && current_u.try(:id) == self.user_id
    else false
    end
  end

  # 可以报价
  def can_bid?
    Bargain.seller_edit_status.include? self.status
    # self.status == 17
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

        <node name='预算金额（元）' column='total'  class='number required' display='readonly'/>
        <node column='budget_id' data_type='hidden'/>

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
    msg << "供应商选择规则： "
    msg << "符合条件的A级供应商必须全部选择，B类供应商可以自行选择；"
    msg << "如果符合条件（可选择）的供应商不足三家，请修改产品参数以便缩小供应商筛选范围。"
  end

  # 没有选择A级供应商的提示
  def self.a_dep_tips
    "你选择的供应商中不包括全部的A级供应商，请重新选择报价供应商！"
  end

  # 中标报价
  def bid_success
    self.bids.find_by(is_bid: true)
  end

  # 有效报价 bid.total != -1
  def effective_bids
    self.bids.where("total != -1")
  end

  # 基准价
  def avg_total
    (self.effective_bids.average(:total) * 0.95).to_f
  end

  # 按基准价排序的报价
  def done_bids
    self.bids.order("abs(total-#{avg_total}), total, bid_time")
  end

  # 第一候选人的报价总金额
  def finish_bid_total
    self.done_bids.first.total
  end

  # 插入order表
  def send_to_order
    return '' unless Bargain.effective_status.include?(self.status)
    order = Order.new
    order.name = self.name
    order.sn = self.sn
    order.contract_sn = self.sn.gsub(self.rule.try(:code), 'ZCL')
    order.buyer_name = self.dep_name
    order.payer = self.invoice_title

    order.buyer_id = self.department_id
    order.buyer_code = self.dep_code

    order.buyer_man = self.dep_man
    order.buyer_tel = self.dep_tel
    order.buyer_mobile = self.dep_mobile
    order.buyer_addr = self.dep_addr

    bid = self.bid_success
    order.seller_name = bid.name
    order.seller_id = bid.department_id
    order.seller_code = bid.department.real_ancestry

    order.seller_man = bid.dep_man
    order.seller_tel = bid.dep_tel
    order.seller_mobile = bid.dep_mobile
    order.seller_addr = bid.dep_addr

    order.budget_id = self.budget_id
    order.budget_money = self.total
    order.total = bid.total

    order.deliver_at = self.updated_at

    order.summary = self.summary
    order.user_id = self.user_id
    order.status = self.status

    order.details = self.details
    order.logs = self.logs.to_s
    order.created_at = self.created_at
    order.updated_at = self.updated_at
    order.yw_type = 'xyyj'

    order.deliver_fee = bid.deliver_fee
    order.other_fee = bid.other_fee
    order.other_fee_desc = bid.other_fee_desc

    bid.products.each do |item|
      xq_item = item.bargain_product
      product = item.product
      order.items.build(
        category_id: self.category_id, category_code: self.category_code,
        category_name: self.category.name, product_id: item.product_id,
        brand: product.brand, model: product.model, version: product.version,
        unit: xq_item.unit, market_price: product.market_price, bid_price: product.bid_price,
        summary: product.summary, quantity: xq_item.quantity, price: item.price, total: item.total,
        details: xq_item.details, item_id: self.item_id
        )
    end

    order.ht_template = self.category.ht_template
    order.save
  end

end
