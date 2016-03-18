# -*- encoding : utf-8 -*-
class Order < ActiveRecord::Base
  has_many :items, class_name: :OrdersItem
  accepts_nested_attributes_for :items
  has_many :uploads, class_name: :OrdersUpload, foreign_key: :master_id
  # default_scope -> {order("id desc")}
  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Order") }, foreign_key: :obj_id
  belongs_to :budget

  scope :find_all_by_buyer_code, ->(dep_real_ancestry) { where("orders.buyer_code like '#{dep_real_ancestry}/%' or orders.buyer_code = '#{dep_real_ancestry}'") }
  scope :find_all_by_seller, ->(seller_id, seller_name) { where("orders.seller_id = #{seller_id} or orders.seller_name = '#{seller_name}'") }
  scope :not_grcg, -> { where("orders.yw_type <> 'grcg'") }
  scope :by_seller_id, ->(seller_id) { where("orders.seller_id = #{seller_id}")}

  validates_with MyValidator
  validate :check_budget
  def check_budget
    errors.add(:base, "订单金额#{self.total.to_f}应小于预算金额#{self.budget_money}") if self.budget_money.to_f > 0 && self.total > self.budget_money
  end

  default_value_for :status, 0

  include AboutStatus

  before_create do
    # 设置rule_id
    self.rule_id = Rule.find_by(yw_type: self.yw_type).try(:id)
    self.rule_step = 'start'
  end

  after_create do
    if self.sn.blank?
      create_no("ZCL", "contract_sn")
      create_no(rule.code, "sn") if rule
    end
  end

  after_save do
    budget.try(:used!)
  end

  before_save do
    self.seller_id = Department.find_by(name: self.seller_name).try(:id) if self.seller_id.blank?
  end

  PTypes = {"xygh" => "单位采购", "grcg" => "个人采购"}

	# 附件的类
  def self.upload_model
    OrdersUpload
  end

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [
    #   ["暂存", "0", "orange", 10], ["等待审核", "8", "blue", 60],
    #   ["审核拒绝", "7", "red", 20], ["自动生效", "2", "yellow", 70],
    #   ["审核通过", "9", "yellow", 70], ["已完成", "100", "u", 100],
    #   ["等待卖方确认", "3", "brown", 30], ["等待买方确认", "4", "light-green", 40],
    #   ["卖方退回", "42", "orange", 20], ["买方退回", "10", "brown", 30],
    #   ["撤回等待审核", "36", "aqua", 30], ["作废等待审核", "43", "aqua", 30],
    #   ["已作废", "47", "dark", 100], ["已撤回", "35", "orange", 20],
    #   ["拒绝撤回", "37", "yellow", 60], ["拒绝作废", "44", "yellow", 60],
    #   ["已拆单", "5", "dark", 100], ["等待收货", "11", "light-green", 50], ["已删除", "404", "dark", 100]
    # ]
    st = self.get_status_array(["暂存", "等待审核", "审核拒绝", "自动生效", "审核通过", "已完成",
      "等待卖方确认", "等待买方确认", "卖方退回", "买方退回", "已拆单", "等待收货",
      "撤回等待审核", "作废等待审核", "已作废", "已撤回", "拒绝撤回", "拒绝作废", "已删除"])

    return BidProject.status_array | st
		# [
	 #    ["未提交",0,"orange",10], ["等待审核",1,"blue",50],
  #     ["审核拒绝",2,"red",0], ["自动生效",5,"yellow",60],
  #     ["审核通过",6,"yellow",60], ["已完成",3,"u",80],
	 #    ["未评价",4,"purple",100], ["已删除",404,"light",0],
  #     ["等待卖方确认", 10, "aqua", 20], ["等待买方确认", 21, "light-green", 40],
  #     ["卖方退回", 15, "orange", 10], ["买方退回", 26, "aqua", 20],
  #     ["撤回等待审核", 32, "sea", 30], ["作废等待审核", 43, "sea", 30],
  #     ["已作废", 49, "red", 0], ["拒绝撤回", 37, "yellow", 60],
  #     ["拒绝作废", 48, "yellow", 60], ["已拆单", 50, "light", 0], ["等待收货", 52, "light", 50]

  #     # 未下单 正在确认 等待审核 正在发货 已发货 已收货 正在退单 已退单 未评价 已完成
  #     # 等待付款 部分付款 已付款 已退款 集中支付
  #   ]
  end

  # def self.effective_status
  #   [3,5,6]
  # end

  # 核对电子凭证真伪的状态
  def self.ysd_status
    [100]
  end

  def self.buyer_status
    (Dictionary.all_status_array.select{ |e| (e[1] % 7 == 4) } & self.status_array).map{ |e| e[1] }
  end

  def self.seller_status
    (Dictionary.all_status_array.select{ |e| (e[1] % 7 == 3) } & self.status_array).map{ |e| e[1] }
  end

  def self.unfinish_status
    self.status_array.map(&:second) - self.finish_status - self.ysd_status
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   status_ha = self.find_step_by_rule.blank? ? 5 : 1
  #   return {
  #     "提交" => { 2 => status_ha, 0 => status_ha },
  #     "通过" => { 1 => 6 },
  #     "不通过" => { 1 => 2 },
  #     "删除" => { 0 => 404 }
  #   }
  # end

  # 根据品目创建项目名称
  def self.get_project_name(order, user, category_names, yw_type = 'xygh')
    yw_type = Dictionary.yw_type[yw_type]
    if order.present?
      project_name = order.name.split(" ")
      project_name[2] = category_names
      return project_name.join(" ")
    else
      name = "#{user.real_department.name} #{Time.new.to_date.to_s} #{category_names}"
      name += " #{yw_type}" if yw_type.present?
      name += "项目"
      return name
    end
  end

  def self.init_order(user, yt = 'xygh')
    order = Order.new
    order.yw_type = yt
    order.buyer_name = order.payer = user.real_department.name
    order.buyer_man = user.name
    order.buyer_tel = user.tel
    order.buyer_mobile = user.mobile
    order.buyer_addr = user.department.address
    order.user_id = user.id
    order.sfz = user.identity_num
    order.buyer_id = user.department.id
    order.buyer_code = user.real_dep_code
    order
  end

  def self.from(cart, user, params = {})
    category_name_ary = []
    order = init_order(user)
    dep = nil
    cart.ready_items.each do |item|
      next if item.ready.blank?
      product = item.product
      order.item_type ||= product.item.item_type
      order.seller_id ||= item.seller_id
      order.items.build(market_price: item.market_price,
        product_id: item.product_id, quantity: item.num, price: item.price,
        category_id: product.category_id, category_code: product.category_code,
        category_name: product.category.name, brand: product.brand, model: product.model,
        version: product.version, unit: product.unit, bid_price: product.bid_price,
        item_id: product.item_id, total: item.num * item.price, vid: item.id
        )
      cart.destroy(item.id) # 清空购物车
      category_name_ary << product.category.name
    end

    # order.items.group_by{|item| item.category.ht_template && item.agent_id}.size

    # 先判断seller_id
    # dep = if order.item_type
    #   Agent.find(order.seller_id).agent_dep
    # else
    dep = Department.find(order.seller_id)
    # end

    order.name = Order.get_project_name(nil, user, category_name_ary.uniq.join("、"))
    order.seller_name = dep.name
    order.seller_code = dep.real_ancestry
    order.seller_addr = dep.address

    if top_user = dep.users.first
      order.seller_man = top_user.name
      order.seller_tel = top_user.tel
      order.seller_mobile = top_user.mobile
    end

    order.deliver_at = Date.today + 3

    if params.present?
      order.attributes = params[:order].permit!
      if order.yw_type == "grcg"
        order.budget_id = nil
        order.payer = "个人"
      else
        order.budget_money = order.budget.try(:total)
      end
      order.items.each_with_index do |item, index|
        if params["item_price_#{item.vid}"].to_f > item.price.to_f
          order.errors.add(:base, "商品采购人报价只能往下调整")
          next
        end
        item.price = params["item_price_#{item.vid}"].to_f;
        item.total = item.quantity * item.price
      end
    end

    # order.total = order.items.map(&:total).sum
    total = order.items.map(&:total).sum
    total += order.deliver_fee if order.deliver_fee.present?
    total += order.other_fee if order.other_fee.present?

    order.total = total

    order
  end

  def buyer_info
    [self.buyer_man, self.buyer_addr, self.buyer_tel, self.buyer_mobile].select{|i| i.present?}.join(" ")
  end

  # 买方单位
  def buyer
    if self.buyer_id.present?
      Department.find_by(id: self.buyer_id).try(:real_dep)
    else
      Department.find_by(name: self.buyer_name)
    end
  end

  # 卖方单位
  def seller
    if self.seller_id.present?
      Department.find_by(id: self.seller_id).try(:real_dep)
    else
      Department.find_by(name: self.seller_name)
    end
  end

  # order_items的category的audit_type数组
  # 获取该订单所有品目的审核类型 返回数组中有>=0的表示总公司审核 <=0表示分公司审核
  def audit_type_array
    self.items.map{ |item| item.category.audit_type }.uniq.compact
  end

  # 获取订单的合同模板
  def get_ht_template
    self.items.map{ |item| item.category.ht_template }.uniq.compact[0]
  end

  # 同一个合同模板才可以下单
  def ht
    "/kobe/orders/ht/#{self.ht_template}"
  end

  # 根据品目判断审核人 插入待办事项用
  def audit_user_ids
    self.items.map{|e| e.category.user_ids}.flatten.uniq
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    tmp = current_u.real_department.is_ancestors?(self.buyer_id) || current_u.real_department.id == self.seller_id
    case act
    when "show"
      tmp
    when "update", "edit"
      self.class.edit_status.include?(self.status) && current_u.try(:id) == self.user_id
    when "commit"
      self.can_opt?("提交") && current_u.try(:id) == self.user_id  && self.budget_money != 0
    when "update_audit", "audit"
      self.class.audit_status.include?(self.status)
    when "invoice_number", "update_invoice_number"
      self.class.effective_status.include?(self.status) && tmp
    when "print", "print_ht", "print_ysd"
      self.class.effective_status.include?(self.status) && tmp
    when "update_agent_confirm", "agent_confirm" # 等待卖方确认
      self.class.seller_status.include?(self.status) && self.seller_id == current_u.real_department.id
    when "update_buyer_confirm", "buyer_confirm" # 等待卖方确认
      self.class.buyer_status.include?(self.status) && self.user_id == current_u.id
    else false
    end
  end

  # 流程图的开始数组
  def step_array
    arr = ["下单"]
    arr |= self.get_obj_step_names
    return arr
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='采购单位' column='buyer_name' class='required' display='readonly'/>
        <node name='发票抬头' column='payer' hint='付款单位，默认与采购单位相同。' class='required'/>
        <node name='采购单位联系人' column='buyer_man' class='required'/>
        <node name='采购单位联系人座机' column='buyer_tel' class='required'/>
        <node name='采购单位联系人手机' column='buyer_mobile' class='required'/>
        <node name='采购单位地址' column='buyer_addr' hint='一般是使用单位。' class='required'/>
        <node name='供应商名称' column='seller_name' class='required'/>
        <node name='供应商单位联系人' column='seller_man' class='required'/>
        <node name='供应商单位联系人座机' column='seller_tel' class='required'/>
        <node name='供应商单位联系人手机' column='seller_mobile' class='required'/>
        <node name='供应商单位地址' column='seller_addr' class='required'/>
        <node name='交付日期' column='deliver_at' class='date_select required dateISO'/>
        <node name='预算金额（元）' column='budget_money' class='number required box_radio' json_url='/kobe/shared/get_budgets_json' partner='budget_id' hint='如果没有可选项，请先填写预算审批单'/>
        <node column='budget_id' data_type='hidden'/>
        <node name='发票编号' column='invoice_number' hint='多张发票请用逗号隔开'/>
        <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
        <node column='total' data_type='hidden'/>
        <node column='yw_type' data_type='hidden'/>
      </root>
    }
  end

  def self.agent_xml
     %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='项目名称' column='name' class='required' display='readonly'/>
        <node name='采购单位' column='buyer_name' class='required' display='readonly'/>
        <node name='发票抬头' column='payer' hint='付款单位，默认与采购单位相同。' display='readonly' class='required'/>
        <node name='采购单位联系人' column='buyer_man' class='required' display='readonly'/>
        <node name='采购单位联系人座机' column='buyer_tel' class='required' display='readonly'/>
        <node name='采购单位联系人手机' column='buyer_mobile' class='required' display='readonly'/>
        <node name='采购单位地址' column='buyer_addr' hint='一般是使用单位。' class='required' display='readonly'/>
        <node name='供应商名称' column='seller_name' class='required'/>
        <node name='供应商单位联系人' column='seller_man' class='required'/>
        <node name='供应商单位联系人座机' column='seller_tel' class='required'/>
        <node name='供应商单位联系人手机' column='seller_mobile' class='required'/>
        <node name='供应商单位地址' column='seller_addr' class='required'/>
        <node name='交付日期' column='deliver_at' class='date_select required dateISO'/>
        <node name='预算金额（元）' column='budget_money' class='number' display='readonly'/>
        <node name='发票编号' column='invoice_number' hint='多张发票请用逗号隔开'/>
        <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
        <node column='total' data_type='hidden'/>
        <node column='yw_type' data_type='hidden'/>
      </root>
    }
  end

  def self.buyer_xml
     %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='项目名称' column='name' class='required' display='readonly'/>
        <node name='采购单位' column='buyer_name' class='required' display='readonly'/>
        <node name='发票抬头' column='payer' hint='付款单位，默认与采购单位相同。' display='readonly' class='required'/>
        <node name='采购单位联系人' column='buyer_man' class='required' />
        <node name='采购单位联系人座机' column='buyer_tel' class='required' />
        <node name='采购单位联系人手机' column='buyer_mobile' class='required' />
        <node name='采购单位地址' column='buyer_addr' hint='一般是使用单位。' class='required' />
        <node name='供应商名称' column='seller_name' class='required' display='readonly'/>
        <node name='供应商单位联系人' column='seller_man' class='required' display='readonly'/>
        <node name='供应商单位联系人座机' column='seller_tel' class='required' display='readonly'/>
        <node name='供应商单位联系人手机' column='seller_mobile' class='required' display='readonly'/>
        <node name='供应商单位地址' column='seller_addr' class='required' display='readonly'/>
        <node name='交付日期' column='deliver_at' class='date_select required dateISO'/>
        <node name='预算金额（元）' column='budget_money' class='number' display='readonly'/>
        <node name='发票编号' column='invoice_number' hint='多张发票请用逗号隔开'/>
        <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
        <node column='total' data_type='hidden'/>
        <node column='yw_type' data_type='hidden'/>
      </root>
    }
  end

  # 高级搜索的搜索条件数组
  def self.search_xml(rule_id)
    status_ha = {}
    self.status_array.each{ |e| status_ha[e[1]] = e[0] unless e[1] == 404 }

    rule = Rule.find_by(id: rule_id).try(:yw_type)
    ha = Dictionary.yw_type
    yw_type_ha = (rule.present? &&  ha.key?(rule)) ? { rule: ha[rule] } : ha.except("grcg")

    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='项目名称' column='sn_or_contract_sn_or_name_cont' placeholder='请输入项目名称或项目编号...'/>
        <node name='采购单位' column='buyer_name_eq' json_url='/kobe/shared/department_ztree_json' class='tree_radio'/>
        <node name='供应商单位' column='seller_name_cont'/>
        <node name='业务类别' column='yw_type_eq' data_type='select' data='#{yw_type_ha}'/>
        <node name='当前状态' column='status_in' data_type='select' data='#{status_ha}'/>
        <node name='开始日期' column='created_at_gt' class='start_date'/>
        <node name='截止日期' column='created_at_lt' class='finish_date'/>
      </root>
    }
  end

  def self.fee_xml
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='运费（元）' column='deliver_fee' class='number'/>
        <node name='其他费用（元）' column='other_fee' class='number' hint='如填写其他费用，请填写其他费用说明'/>
        <node name='其他费用说明' column='other_fee_desc' placeholder='不超过800字'/>
      </root>
    }
  end

end
