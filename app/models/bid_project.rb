# -*- encoding : utf-8 -*-
class BidProject < ActiveRecord::Base
  # has_many :uploads, as: :master

  has_many :uploads, class_name: :BidProjectUpload, foreign_key: :master_id

  has_many :items, class_name: "BidItem"
  has_many :bid_item_bids
  has_many :bid_project_bids
  belongs_to :bid_project_bid

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "BidProject") }, foreign_key: :obj_id

  belongs_to :user
  belongs_to :item
  belongs_to :department

  belongs_to :budget

  default_value_for :status, 0

  scope :can_bid, -> { where("bid_projects.status = #{BidProject.bid_and_choose_status} and now() < bid_projects.end_time") }

  scope :find_all_by_buyer_code, ->(dep_real_ancestry) { where("bid_projects.department_code like '#{dep_real_ancestry}/%' or bid_projects.department_code = '#{dep_real_ancestry}'") }

  # 模型名称
  Mname = "网上竞价项目"

  # 附件的类
  def self.upload_model
    BidProjectUpload
  end

  before_create do
    # 设置rule_id和rule_step
    self.rule_id = Rule.find_by(yw_type: 'wsjj_xq').try(:id)
    self.rule_step = 'start'
  end

  after_create do
    create_no

  end

  include AboutStatus

  # 可投标 可选择中标人的状态
  def self.bid_and_choose_status
    16
  end

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [
    #   ["暂存", "0", "orange", 10],
    #   ["需求等待审核", "15", "blue", 30],
    #   ["需求审核拒绝", "14", "red", 20],
    #   ["已发布", "16", "yellow", 40],
    #   ["结果等待审核", "22", "sea", 60],
    #   ["结果审核拒绝", "21", "purple", 50],
    #   ["确定中标人", "23", "yellow", 100],
    #   ["废标等待审核", "29", "sea", 60],
    #   ["废标审核拒绝", "28", "purple", 50],
    #   ["已废标", "33", "dark", 100],
    #   ["已删除", "404", "dark", 100]
    # ]
    self.get_status_array(["暂存", "需求等待审核", "需求审核拒绝", "已发布", "结果等待审核", "结果审核拒绝", "已成交", "废标等待审核", "废标审核拒绝", "已废标", "已删除"])
		# [
	 #    ["暂存", 0, "orange", 20],
  #     ["需求等待审核", 1, "blue", 40],
  #     ["需求审核拒绝",3,"red", 0],
	 #    ["已发布", 2, "orange", 50],
  #     ["结果等待审核", 4, "sea", 70],
  #     ["结果审核拒绝",5,"red", 50],
  #     ["确定中标人", 12, "u", 100],
  #     ["废标等待审核", 6, "sea", 70],
  #     ["废标审核拒绝",7,"red", 50],
  #     ["已废标", -1, "red", 100],
	 #    ["已删除", 404, "light", 0]
  #   ]
  end
   # 根据不同操作 改变状态
  # def change_status_hash
  #   status_ha = self.find_step_by_rule.blank? ? 2 : 1
  #   return {
  #     "提交审核" => { 3 => status_ha, 0 => status_ha },
  #     "删除" => { 0 => 404 },
  #     "通过" => { 1 => 2, 4 => 12, 6 => -1 },
  #     "确定中标人" => {2 => 4},
  #     "废标" => {2 => 6},
  #     "不通过" => { 1 => 3, 4 => 5, 6 => 7 }
  #   # }
  # end

  # 最低报价
  def lowest_bid
    self.bid_project_bids.order("bid_project_bids.total ASC, bid_project_bids.bid_time ASC").first
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    case act
    when "show"
      true
    when "update", "edit"
      self.class.edit_status.include?(self.status) && current_u.try(:id) == self.user_id
    when "commit"
      self.can_opt?("提交") && current_u.try(:id) == self.user_id  && self.budget_money != 0
    when "update_audit", "audit"
      self.class.audit_status.include?(self.status)
    when "delete", "destroy"
      self.can_opt?("删除") && current_u.try(:id) == self.user_id
    when "choose", "update_choose"
      self.can_choose? && current_u.try(:id) == self.user_id
    else false
    end
  end

  # 可以选择中标人
  def can_choose?
    self.status == BidProject.bid_and_choose_status && self.is_end? || BidProject.buyer_edit_status.include?(self.status)
  end

  def is_end?
    Time.now - self.end_time > 0
  end

  def can_bid?
    self.status == BidProject.bid_and_choose_status && !is_end?
  end

  # 判断用户是否可以报价 主要判断是否是指定的入围供应商
  def check_user_can_bid?(user)
    (item.present? && item.departments.include?(user.department)) || item.blank?
  end

  # def show_logs
  #   if can_bid?
  #     doc = Nokogiri::XML(self.logs)
  #     # note = doc.search("/root/node[(@操作内容='报价')]") # find all tags with the node_name "note"
  #     note = doc.search("/root/node[(@操作内容='报价')] | /root/node[(@操作内容='修改报价')]")
  #     note.remove
  #     doc
  #   else
  #     Nokogiri::XML(self.logs)
  #   end
  # end

  # 根据品目判断审核人 插入待办事项用
  def audit_user_ids
    self.items.map{|e| e.category.user_ids}.flatten.uniq
  end

  # 获取提示信息 用于1.注册完成时提交的提示信息、2.登录后验证个人信息是否完整
  # def get_tips
  #   msg = []
  #   return msg
  # end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='采购单位' column='buyer_dep_name' class='required' display= "readonly" />
        <node name='发票抬头' column='invoice_title' />
        <node name='采购人姓名' column='buyer_name' class='required' />
        <node name='采购人电话' column='buyer_phone' class='required' />
        <node name='采购人手机' column='buyer_mobile' class='required' />
        <node name='采购人地址' column='buyer_add' class='required' />
        <node name='明标或暗标' column='lod' class='required' data='#{Dictionary.lod}' data_type='radio' />
        <node name='投标截止时间' column='end_time' class='required datetime_select datetime' />
        <node name='资质要求' column='req' data_type='textarea' class='required' />
        <node column='item_id' data_type='hidden'/>
        <node name='指定入围供应商' hint='粮机设备应该从入围供应商处采购' class='box_radio' json_url='/kobe/shared/item_ztree_json' json_params='{"vv_otherchoose":"允许非入围供应商报价"}' partner='item_id'/>
        <node name='预算金额（元）' column='budget_money' class='number required' display='readonly'/>
        <node column='budget_id' data_type='hidden'/>
        <node name='备注信息' column='remark' data_type='textarea' />
      </root>
    }
  end

  # 插入order表
  def send_to_order
    return '' unless self.status == 23
    order = Order.new
    order.name = self.name
    order.sn = self.code
    order.contract_sn = self.code.gsub(self.rule.try(:code), 'ZCL')
    order.buyer_name = self.buyer_dep_name
    order.payer = self.invoice_title

    order.buyer_id = self.department_id
    order.buyer_code = self.department_code

    order.buyer_man = self.buyer_name
    order.buyer_tel = self.buyer_phone
    order.buyer_mobile = self.buyer_mobile
    order.buyer_addr = self.buyer_add

    bid = self.bid_project_bid
    order.seller_name = bid.com_name
    order.seller_id = bid.department_id
    order.seller_code = bid.department.real_ancestry

    order.seller_man = bid.username
    order.seller_tel = bid.tel
    order.seller_mobile = bid.mobile
    order.seller_addr = bid.add

    order.budget_id = self.budget_id
    order.budget_money = self.budget_money
    order.total = bid.total

    order.deliver_at = self.updated_at

    order.summary = self.req
    order.user_id = self.user_id
    order.status = self.status

    order.details = self.details
    order.logs = self.logs.to_s
    order.created_at = self.created_at
    order.updated_at = self.updated_at
    order.yw_type = 'wsjj'

    bid.items.each do |item|
      xq_item = item.bid_item
      order.items.build(
        quantity: xq_item.num, price: item.price,
        category_id: xq_item.category_id, category_code: xq_item.category.ancestry,
        category_name: xq_item.category.name, brand: item.brand_name,
        version: item.xh, unit: xq_item.unit,  total: item.total, summary: item.req
        )
    end

    order.ht_template = self.items.map{ |item| item.category.ht_template }.uniq.compact[0]
    order.save
  end

end
