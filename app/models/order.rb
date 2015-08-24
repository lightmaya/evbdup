# -*- encoding : utf-8 -*-
class Order < ActiveRecord::Base
	has_many :items, class_name: :OrdersItem
	has_many :uploads, class_name: :OrdersUpload, foreign_key: :master_id
  default_scope -> {order("id desc")}

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Order") }, foreign_key: :obj_id

  validates_with MyValidator

	include AboutStatus

  before_save do
    if self.items.present?
      project_name = self.name.split(" ")
      project_name[2] = self.items.map(&:category_name).join("、")
      self.name = project_name.join(" ")
    end
  end

  before_create do
    # 生成sn、contract_sn
    maxid = Order.maximum('id').to_i + 1
    if maxid.to_s.length > 4
      uniq_id = maxid.to_s[-4..maxid.to_s.length]
    else
      uniq_id = "%04d" % maxid
    end
    timestamps = Time.new.strftime('%Y%m%d%H')
    self.sn = "#{Dictionary.order_sn.ddcg}#{timestamps}#{uniq_id}"
    self.contract_sn = "ZCL-#{timestamps}#{uniq_id}"

    # 设置rule_id
    self.rule_id = Rule.find_by(name: '定点采购').id
  end

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
      ["自动生效",2,"yellow",60],
      ["审核通过",2,"yellow",60],
	    ["已完成",3,"u",80],
	    ["未评价",4,"purple",100],
	    ["已删除",404,"light",0]
      # 未下单 正在确认 等待审核 正在发货 已发货 已收货 正在退单 已退单 未评价 已完成
      # 等待付款 部分付款 已付款 已退款 集中支付
    ]
  end

  # 根据不同操作 改变状态
  def change_status_hash
    ha = {
      "提交" => { "审核拒绝" => "等待审核" },
      "通过" => { "等待审核" => "正常" },
      "不通过" => { "等待审核" => "审核拒绝" },
      "删除" => { "未提交" => "已删除" },
    }
    if self.find_step_by_rule.blank?
      ha["提交"]["未提交"] = "自动生效" 
    else
      ha["提交"]["未提交"] = "等待审核" 
    end
    return ha
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
    self.items.map{ |item| item.category.audit_type }.uniq
  end

  # can_opt_arr = [:create, :read, :update] 对应cancancan验证的action 
  def cando_list(can_opt_arr=[],only_audit=false)
    arr = [] 
    # 查看详细
    arr << [self.class.icon_action("详细"), "/kobe/orders/#{self.id}", target: "_blank"] if can_opt_arr.include?(:read)
    # 修改
    if [0,2].include?(self.status)
    	arr << [self.class.icon_action("修改"), "/kobe/orders/#{self.id}/edit"] if can_opt_arr.include?(:update)
    # 提交
    	arr << [self.class.icon_action("提交"), "/kobe/orders/#{self.id}/commit", method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if self.can_opt?("提交")
    end
    # 审核
    if self.status == 2
      audit_opt = [self.class.icon_action("审核"), "/kobe/orders/#{self.id}/audit"] if can_opt_arr.include?(:audit)
      return [audit_opt] if only_audit
      arr << audit_opt
    end

   #  # 确认
   #  if [0,1,404].include?(self.status)
   #  	arr << [self.class.icon_action("确认订单"), "/kobe/orders/#{self.id}/confirm"]
   #  end

   #  # 打印
   #  if [0,1,404].include?(self.status)
   #  	arr << [self.class.icon_action("打印"), "/kobe/orders/#{self.id}/print", target: "_blank"]
   #  end
   #  # 删除
   #  if [0,1,3,4].include?(self.status)
	  #   arr << [self.class.icon_action("删除"), "/kobe/orders/#{self.id}", method: :delete, data: {confirm: "确定要删除吗?"}]
	  # end
   #  # 彻底删除
   #  if self.status == 404
	  #   arr << [self.class.icon_action("彻底删除"), "/kobe/orders/#{self.id}", method: :delete, data: {confirm: "删除后不可恢复，确定要删除吗?"}]
	  # end
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
      </root>
    }
  end

end
