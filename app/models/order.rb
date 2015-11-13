# -*- encoding : utf-8 -*-
class Order < ActiveRecord::Base
	has_many :items, class_name: :OrdersItem
	has_many :uploads, class_name: :OrdersUpload, foreign_key: :master_id
  # default_scope -> {order("id desc")}

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Order") }, foreign_key: :obj_id

  scope :find_all_by_buyer_code, ->(dep_real_ancestry) { where("buyer_code like '#{dep_real_ancestry}/%' or buyer_code = '#{dep_real_ancestry}'") }

  validates_with MyValidator

	include AboutStatus

  before_create do
    # 设置rule_id
    self.rule_id = Rule.find_by(yw_type: self.yw_type).try(:id)
  end

  after_create do 
    create_no("ZCL", "contract_sn")
    create_no(rule.code, "sn")
  end

  PTypes = {"xygh" => "单位采购", "grcg" => "个人采购"}

	# 附件的类
  def self.upload_model
    OrdersUpload
  end

	# 中文意思 状态值 标签颜色 进度 
	def self.status_array
		[
	    ["未提交",0,"orange",10],
	    ["等待审核",1,"blue",50],
      ["审核拒绝",2,"red",0],
      ["自动生效",5,"yellow",60],
      ["审核通过",6,"yellow",60],
	    ["已完成",3,"u",80],
	    ["未评价",4,"purple",100],
	    ["已删除",404,"light",0]
      # 未下单 正在确认 等待审核 正在发货 已发货 已收货 正在退单 已退单 未评价 已完成
      # 等待付款 部分付款 已付款 已退款 集中支付
    ]
  end

  def self.effective_status
     [3,5,6]
  end

  # 根据不同操作 改变状态
  def change_status_hash
    status_ha = self.find_step_by_rule.blank? ? 5 : 1 
    return {
      "提交" => { 2 => status_ha, 0 => status_ha },
      "通过" => { 1 => 6 },
      "不通过" => { 1 => 2 },
      "删除" => { 0 => 404 }
    }
  end

  # 提交时需更新的参数 主要用于更新rule_step
  # 返回 change_status_and_write_logs(opt,stateless_logs,update_params=[]) 的update_params 数组
  def commit_params
    arr = []
    if self.find_step_by_rule.blank?
      arr << "rule_step = 'done'"
    else
      arr << "rule_step = 'start'"
    end
    return arr
  end

	# 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	limited = [404]
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  # 根据品目创建项目名称
  def self.get_project_name(order, user, category_names)
    yw_type = ''
    if order.present?
      project_name = order.name.split(" ")
      project_name[2] = category_names
      return project_name.join(" ")
      yw_type = Dictionary.yw_type(order.yw_type)
    else
      name = "#{user.real_department.name} #{Time.new.to_date.to_s} #{category_names}"
      name += " #{yw_type}" if yw_type.present?
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
    order
  end


  def buyer_info
    [self.buyer_man, self.buyer_addr, self.buyer_tel, self.buyer_mobile].select{|i| i.present?}.join(" ")
  end

  # 买方单位
  def buyer
    if self.buyer_id.present?
      Department.find_by(id: self.buyer_id)
    else
      Department.find_by(name: self.buyer_name)
    end
  end

  # 卖方单位
  def seller
    if self.seller_id.present?
      Department.find_by(id: self.seller_id)
    else
      Department.find_by(name: self.seller_name)
    end
  end

  # order_items的category的audit_type数组
  # 获取该订单所有品目的审核类型 返回数组中有>=0的表示总公司审核 <=0表示分公司审核
  def audit_type_array
    self.items.map{ |item| item.category.audit_type }.uniq.compact
  end

  # 同一个合同模板才可以下单
  def ht
    ht = self.items.map{ |item| item.category.ht_template }.uniq.compact.join
    return "/kobe/orders/ht/#{ht}"
  end
  
  # 根据品目判断审核人 插入待办事项用
  def audit_user_ids
    self.items.map{|e| e.category.user_ids}.flatten.uniq
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    case act
    when "show" 
      current_u.department.is_ancestors?(self.buyer_id)
    when "update", "edit" 
      [0,2].include?(self.status) && current_u.try(:id) == self.user_id
    when "commit" 
      self.can_opt?("提交") && current_u.try(:id) == self.user_id
    when "update_audit", "audit" 
      self.status == 1
    when "print" 
      [3,5,6].include?(self.status) && current_u.department.is_ancestors?(self.buyer_id)
    else false
    end
  end

  # 流程图的开始数组
  def step_array
    arr = ["下单", "提交"]
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
        <node name='预算金额（元）' column='budget' class='required number'/>
        <node name='发票编号' column='invoice_number' hint='多张发票请用逗号隔开'/>
        <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
        <node column='total' data_type='hidden'/>
        <node column='yw_type' data_type='hidden'/>
      </root>
    }
  end

  # 高级搜索的搜索条件数组
  def self.advanced_search_array
    arr = []
    arr << { name: 'sn_or_contract_sn_or_name_cont', label: '项目名称、凭证编号、合同编号' }
    arr << { name: 'buyer_name_cont', label: '采购单位',  json_url: "/kobe/shared/department_ztree_json", class_name: 'tree_radio' }
    arr << { name: 'seller_name_cont', label: '供应商单位' }
    arr << { name: 'yw_type_cont', label: '业务类别' }
    arr << { name: 'status_cont', label: '当前状态' }
    arr << { name: 'created_at_gt', label: '开始日期', class_name: 'start_date' }
    arr << { name: 'created_at_lt', label: '截止日期', class_name: 'finish_date' }
    return arr 
  end

end
