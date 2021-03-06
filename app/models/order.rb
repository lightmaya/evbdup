# -*- encoding : utf-8 -*-
class Order < ActiveRecord::Base
  has_many :items, class_name: :OrdersItem
  accepts_nested_attributes_for :items
  has_many :uploads, class_name: :OrdersUpload, foreign_key: :master_id
  has_many :other_uploads, -> { where(yw_type: "cancel") }, foreign_key: :master_id
  # default_scope -> {order("id desc")}
  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Order") }, foreign_key: :obj_id
  belongs_to :budget
  belongs_to :rate

  scope :find_all_by_buyer_code, ->(real_dep_id) { where("find_in_set(#{real_dep_id}, replace(orders.buyer_code, '/', ',')) > 0") }
  scope :find_all_by_seller, ->(seller_id, seller_name) { where("orders.seller_id = #{seller_id} or orders.seller_name = '#{seller_name}'") }
  scope :not_grcg, -> { where("orders.yw_type <> 'grcg'") }
  scope :by_seller_id, ->(seller_id) { where("orders.seller_id = #{seller_id}")}

  has_one :audit, -> { where(class_name: "Order") }, foreign_key: :obj_id, class_name: :BatchAudit
  scope :batch_audits, -> { joins(:batch_audits).where(class_name: "Order") }

  validates_with MyValidator
  # validate :check_budget
  # def check_budget
  #   errors.add(:base, "订单金额#{self.total.to_f}应小于预算金额#{self.budget_money}") if self.budget_money.to_f > 0 && self.total > self.budget_money
  # end

  default_value_for :status, 0
  default_value_for :budget_money, 0
  default_value_for :rate_total, 20

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

  before_save do
    self.seller_id = Department.find_by(name: self.seller_name, ancestry: Dictionary.dep_supplier_id).try(:id) if self.seller_id.blank?
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
    self.get_status_array(["暂存", "等待审核", "审核拒绝", "自动生效", "审核通过", "已完成",
      "等待卖方确认", "等待买方确认", "卖方退回", "买方退回", "已拆单", "等待收货", "等待评价",
      "撤回等待审核", "作废等待审核", "已作废", "已撤回", "拒绝撤回", "拒绝作废", "已删除", "已成交", "汇款处理中", "等待汇款"])

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

  # 可以评价或查看评价的状态
  def self.rate_status
    [93, 100]
  end

  def self.buyer_status
    [4]
  end

  def self.seller_status
    [3, 10]
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
    if order.present? && order.name.present?
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
    order.buyer_tel = user.tel.blank? ? '-' : user.tel
    order.buyer_mobile = user.mobile.blank? ? '-' : user.mobile
    order.buyer_addr = user.department.address.blank? ? '-' : user.department.address
    order.user_id = user.id
    order.sfz = user.identity_num
    order.buyer_id = user.department.id
    order.buyer_code = user.real_dep_code
    order
  end

  def self.from_cart(cart, user, params = {})
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
        item_id: product.item_id, total: item.num * item.price, vid: item.id, summary: item.summary
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
    if params[:yw_type].present?
      order.yw_type = params[:yw_type]
      order.budget_id = nil
      order.payer = "个人"
    end

    order.name = Order.get_project_name(nil, user, category_name_ary.uniq.join("、"), order.yw_type)
    order.seller_name = dep.name
    order.seller_code = dep.real_ancestry
    order.seller_addr = dep.address

    if top_user = dep.users.first
      order.seller_man = top_user.name
      order.seller_tel = top_user.tel
      order.seller_mobile = top_user.mobile
    end

    order.deliver_at = Date.today + 3

    # if params.present?
    #   order.attributes = params[:order].permit!
    #   if order.yw_type == "grcg"
    #     order.budget_id = nil
    #     order.payer = "个人"
    #   else
    #     order.budget_money = order.budget.try(:total)
    #   end
    #   order.items.each_with_index do |item, index|
    #     if params["item_price_#{item.vid}"].to_f > item.price.to_f
    #       order.errors.add(:base, "商品采购人报价只能往下调整")
    #       next
    #     end
    #     item.price = params["item_price_#{item.vid}"].to_f;
    #     item.total = item.quantity * item.price
    #   end
    # end

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

  # 显示上级单位
  def show_top_name
    self.buyer.try(:top_dep).present? ? "[ #{self.buyer.top_dep.name} ]" : ""
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
    self.items.map{ |item| item.category.try(:audit_type) }.uniq.compact
  end

  # 获取订单的合同模板
  def get_ht_template
    self.items.map{ |item| item.category.try(:ht_template) }.uniq.compact[0]
  end

  # 同一个合同模板才可以下单
  def ht
    "/kobe/orders/ht/#{self.ht_template}"
  end

  # 根据合同模板 判断是哪类订单
  def ot
    order_type = ""
    Dictionary.order_type.each do |k, arr|
      order_type = k
      break if arr[1].include?(self.ht_template)
    end
    return order_type
  end

  # 根据品目判断审核人 插入待办事项用
  def audit_user_ids
    self.items.map{ |e| e.category.try(:user_ids) }.flatten.uniq
  end

  # 根据action_name 判断obj有没有操作
  # def cando(act='',current_u=nil)
    # tmp = current_u.real_department.is_ancestors?(self.buyer_id) || current_u.real_department.id == self.seller_id || current_u.real_department.name == self.seller_name
    # case act
    # when "show"
    #   tmp
    # when "update", "edit"
    #   (self.class.edit_status.include?(self.status) && current_u.try(:id) == self.user_id) || current_u.is_boss?
    # when "commit"
    #   self.can_opt?("提交") && current_u.try(:id) == self.user_id  && self.budget_money != 0
    # when "update_audit", "audit"
    #   self.class.audit_status.include?(self.status)
    # when "invoice_number", "update_invoice_number"
    #   self.class.effective_status.include?(self.status) && tmp
    # when "print", "print_ht", "print_ysd"
    #   self.class.effective_status.include?(self.status) && tmp
    # when "update_agent_confirm", "agent_confirm" # 等待卖方确认
    #   self.class.seller_status.include?(self.status) && self.seller_id == current_u.real_department.id
    # when "update_buyer_confirm", "buyer_confirm" # 等待卖方确认
    #   self.class.buyer_status.include?(self.status) && self.user_id == current_u.id
    # when "delete", "destroy"
    #   self.can_opt?("删除") && current_u.try(:id) == self.user_id
    # when "rating", "update_rating"
    #   self.class.rate_status.include?(self.status) && current_u.try(:id) == self.user_id
    # else false
    # end
  # end

  def cando_hash(current_u=nil)
    ha = Hash.new
    tmp = current_u.real_department.is_ancestors?(self.buyer_id) || current_u.real_department.id == self.seller_id || current_u.real_department.name == self.seller_name
    only_self = current_u.try(:id) == self.user_id
    ha["show"] = tmp
    ha["update"] = ha["edit"] = (self.class.edit_status.include?(self.status) && only_self) || current_u.is_boss?
    ha["commit"] = self.can_opt?("提交") && only_self  && (self.budget_money != 0 && self.yw_type != 'grcg' || self.yw_type == 'grcg')
    ha["update_audit"] = ha["audit"] = self.class.audit_status.include?(self.status)
    ha["invoice_number"] = ha["update_invoice_number"] = ha["print"] = ha["print_ht"] = ha["print_ysd"] = self.class.effective_status.include?(self.status) && tmp
    # 等待卖方确认
    ha["update_agent_confirm"] = ha["agent_confirm"] = self.class.seller_status.include?(self.status) && self.seller_id == current_u.real_department.id
    # 等待买方确认
    ha["update_buyer_confirm"] = ha["buyer_confirm"] = self.class.buyer_status.include?(self.status) && only_self
    ha["delete"] = ha["destroy"] = self.can_opt?("删除") && only_self
    ha["rating"] = ha["update_rating"] = self.class.rate_status.include?(self.status) && only_self
    ha["cancel"] = ha["update_cancel"] = self.class.effective_status.include?(self.status) && (only_self || current_u.is_boss?)
    return ha.delete_if{|key,value|value == false}
  end

  # 流程图的开始数组
  def step_array
    arr = ["下单"]
    arr |= self.get_obj_step_names
    arr << "评价"
    return arr
  end

  # 查看网上竞价、协议议价过程
  def link_to_road
    return '' unless ["wsjj", "xyyj"].include?(self.yw_type)
    url = self.yw_type == "xyyj" ? "bargains" : "bid_projects"
    name = self.yw_type == "xyyj" ? "议价" : "竞价"
    "<a href='/kobe/#{url}/#{self.mall_id}' target='_blank'>查看#{name}记录</a>"
  end

  def self.xml(order=nil, current_u='', options={})
    buyer_edit = seller_edit = ''
    if ['xygh', 'grcg'].include?(order.try(:yw_type))
      buyer_edit = " display='readonly'" if order.try(:seller_id) == current_u.real_department.id
      seller_edit = " display='readonly'" if order.try(:buyer_id) == current_u.real_department.id
    end

    dep_s_tmp = case order.try(:yw_type)
    when 'ddcg'
      %Q{ hint='有入围供应商的项目应该从入围供应商处采购' class='tree_radio required' json_url='/kobe/shared/item_dep_json' json_params='{"vv_otherchoose":"从非入围供应商采购","vv_checklevel":-1}' partner='seller_id' }
    when 'jhcg'
      oi = order.plan_key.split("_")
      %Q{ hint='有入围供应商的项目应该从入围供应商处采购' class='box_radio required' json_url='/kobe/plans/bid_dep_ztree_json' json_params='{"item_id": "#{oi[0]}", "category_id": "#{oi[1]}"}' partner='seller_id' }
    else
      " display='readonly'"
    end

    budget = unless order.try(:yw_type) == 'grcg'
      %Q{
        <node name='预算金额（元）' column='budget_money' class='number required' display='readonly'/>
        <node column='budget_id' data_type='hidden'/>
      }
    else
      %Q{
        <node name='采购人身份证号码' column='sfz' class='required' #{buyer_edit}/>
      }
    end

    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='采购单位' column='buyer_name' class='required' display='readonly'/>
        <node name='发票抬头' column='payer' hint='付款单位，默认与采购单位相同。' class='required' #{buyer_edit}/>
        <node name='采购单位联系人' column='buyer_man' class='required' #{buyer_edit}/>
        <node name='采购单位联系人座机' column='buyer_tel' class='required' #{buyer_edit}/>
        <node name='采购单位联系人手机' column='buyer_mobile' class='required' #{buyer_edit}/>
        <node name='采购单位地址' column='buyer_addr' hint='一般是使用单位。' class='required' #{buyer_edit}/>
        <node column='seller_id' data_type='hidden'/>
        <node name='供应商名称' column='seller_name' #{dep_s_tmp}/>
        <node name='供应商单位联系人' column='seller_man' class='required' #{seller_edit}/>
        <node name='供应商单位联系人座机' column='seller_tel' #{seller_edit}/>
        <node name='供应商单位联系人手机' column='seller_mobile' class='required' #{seller_edit}/>
        <node name='供应商单位地址' column='seller_addr' class='required' #{seller_edit}/>
        <node name='交付日期' column='deliver_at' class='date_select required dateISO'/>
        #{budget}
        <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
        <node column='total' data_type='hidden'/>
        <node column='yw_type' data_type='hidden'/>
        <node column='plan_key' data_type='hidden'/>
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

    ht_ha = Dictionary.order_type.map{|k,v| [k, v[0]]}

    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='项目名称' column='sn_or_contract_sn_or_name_cont' placeholder='请输入项目名称或项目编号...'/>
        <node name='采购单位' column='buyer_name' json_url='/kobe/shared/department_ztree_json' class='tree_radio'/>
        <node name='供应商单位' column='seller_name_cont'/>
        <node name='业务类别' column='yw_type_eq' data_type='select' data='#{yw_type_ha}'/>
        <node name='订单类别' column='ot' data_type='select' data='#{ht_ha}'/>
        <node name='当前状态' column='status_in' data_type='select' data='#{status_ha}'/>
        <node name='品目' column='items_category_name' class='tree_checkbox required' json_url='/kobe/shared/category_ztree_json'/>
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

  def self.tips
    %w(1、定点采购实行二级审核，选择的品目与实际采购物品不符的，一律审核不通过。例如品目选择“硒鼓”，实际采购计算机或其他设备的。
    2、有入围供应商的项目应选择入围供应商进行采购。
    3、经过招标程序的项目，应上传专家评标决议。未招标的项目应上传供应商询价表（三家以上），或者上传采购单位针对本次采购的询价情况说明。
    4、不在采购目录范围内的物资设备，可按有关规定自行采购，无需在系统中录入。)
  end

end
