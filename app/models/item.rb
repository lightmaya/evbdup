# -*- encoding : utf-8 -*-
class Item < ActiveRecord::Base
  has_many :item_categories, dependent: :destroy
  has_many :categories, through: :item_categories
  has_many :item_departments, dependent: :destroy
  has_many :departments, through: :item_departments
  has_many :coordinators
  has_many :agents
  # 未注册的入围供应商
  has_many :unregistered_departments, -> { where(department_id: nil) }, class_name: "ItemDepartment", dependent: :destroy
  # 已注册的入围供应商
  has_many :registered_departments, -> { where.not(department_id: nil) }, class_name: "ItemDepartment", dependent: :destroy
  # 项目订单
  has_many :orders_items
  has_many :orders, -> { distinct }, through: :orders_items
  # default_scope -> {order("id desc")}

  scope :usable, -> { where("items.status = #{Item.effective_status.join(', ')} and now() < items.end_time") }
  scope :can_search, -> { where(status: [65, 68, 54]) }

  default_value_for :status, 0

  before_save do
    self.category_ids = self.categoryids.split(",") - ["734"]
  end

  after_save do
    if self.dep_names.present?
      self.dep_names.split("\r\n").each do |name|
        dep = Department.find_by(name: name)
        tmp = (dep.present? ? { name: name, department_id: dep.id } : { name: name })
        self.item_departments.find_or_create_by(tmp)
      end
    end
  end

  def self.fix_dep_names
    Item.all.each do |item|
      dns = item.item_departments.map(&:name).join("\r\n")
      item.update(dep_names: dns)
    end
  end

  include AboutStatus

  # 是否过了有效期
  def is_end?
    Time.now > self.end_time
  end

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [
    #   ["暂存", "0", "orange", 10],
    #   ["正常", "65", "yellow", 100],
    #   ["停止申请", "68", "dark", 100],
    #   ["已过期", "54", "dark", 100],
    #   ["已删除", "404", "dark", 100]
    # ]
    self.get_status_array(["暂存", "正常", "停止申请", "已过期", "已删除"])
		# [
	 #    ["暂存",0,"orange",10],
	 #    ["有效",1,"blue",100],
  #     ["停止申请",2,"red",50],
	 #    ["已删除",404,"light",0],
  #     ["已停止", 3, "red", 60]
  #   ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   {
  #     "提交" => { 0 => 1 },
  #     "停止" => { 1 => 2 },
  #     "恢复" => { 2 => 1 },
  #     "删除" => { 0 => 404 }
  #   }
  # end

  # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  # 	# 列表中不允许出现的
  # 	limited = [404]
  # 	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

  def cando(act='',current_u=nil)
    case act
    when "update", "edit"
      self.class.edit_status.include?(self.status)
    when "commit"
      self.can_opt?("提交")
    when "delete", "destroy"
      self.can_opt?("删除")
    when "recover", "update_recover"
      self.can_opt?("恢复")
    when "pause", "update_pause"
      self.can_opt?("停止")
    when "add_product"
      self.finalist?(current_u.department.id) && self.class.effective_status.include?(self.status)
    when "add_agent"
      self.finalist?(current_u.department.id) && self.class.effective_status.include?(self.status) && self.item_type
    when "add_coordinator"
      self.finalist?(current_u.department.id) && self.class.effective_status.include?(self.status) && self.item_type
    else false
    end
  end

  # 根据 department_id 判断该单位是否入围本项目
  def finalist?(department_id)
    item_department = self.registered_departments.find_by(department_id: department_id)
    return item_department.present?
  end

  # 保存后提示哪些供应商已经注册 哪些没有注册
  def tips
    unregistered_names = self.unregistered_departments.map(&:name).join("<br/> ")
    registered_names = self.registered_departments.map(&:name).join("<br/> ")
    tips = []
    tips << "<span class='red'>以下单位还未注册，请联系供应商注册：</span><br/> #{unregistered_names}" if unregistered_names.present?
    tips << "<span class='red'>以下单位已注册，提交项目后给这些供应商发送站内消息：</span><br/> #{registered_names}" if registered_names.present?
    return tips
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='项目名称' column='name' class='required'/>
        <node name='项目类型' column='item_type' data_type='radio' data='#{Dictionary.item_type}'/>
        <node name='品目分配' class='tree_checkbox required' json_url='/kobe/shared/category_ztree_json' partner='categoryids'/>
        <node column='categoryids' data_type='hidden'/>
        <node name='有效期开始时间' column='begin_time' class='required datetime_select datetime'/>
        <node name='有效期截止时间' column='end_time' class='required datetime_select datetime'/>
        <node name='入围供应商' column='dep_names' data_type='textarea' class='required' hint='请用回车作为分隔符'/>
      </root>
    }
  end

end
