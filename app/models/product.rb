# -*- encoding : utf-8 -*-
class Product < ActiveRecord::Base
	has_many :uploads, class_name: :ProductsUpload, foreign_key: :master_id
	belongs_to :category
  belongs_to :item
  belongs_to :department

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Product") }, foreign_key: :obj_id
  scope :show, -> {where("products.status = 1")}

  include AboutStatus

  before_create do
    # 设置rule_id和rule_step
    init_rule
  end
  
  QS = ["category_id_eq", "brand_eq", "sort", "page"]

	# 附件的类
  def self.upload_model
    ProductsUpload
  end

  def agents
    # item.try(:agents)
    Agent.where(department_id: self.department_id, item_id: self.item_id).includes(:agent_dep)
  end

  def show
    self.status == 1
  end

  # 产品全称 品牌+型号+版本号
  def name
    "#{self.brand} #{self.model} #{self.version}"
  end

  # 中文意思 状态值 标签颜色 进度 
  def self.status_array
    [
      ["未提交",0,"orange",10],
      ["正常",1,"u",100],
      ["等待审核",2,"blue",50],
      ["审核拒绝",3,"red",0],
      ["已下架",4,"yellow",20],
      ["已删除",404,"light",0]
    ]
  end

  # 根据不同操作 改变状态
  def change_status_hash
    status_ha = self.find_step_by_rule.blank? ? 1 : 2
    return {
      "提交" => { 3 => status_ha, 0 => status_ha },
      "通过" => { 2 => 1 },
      "不通过" => { 2 => 3 },
      "删除" => { 0 => 404 },
      "下架" => { 1 => 4 },
      "恢复" => { 4 => 1 }
    }
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	limited = [404]
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  def cover_url(style = :md)
    uploads.first.upload.url(style.to_sym) if uploads.present?
  end

  # 根据品目判断审核人 插入待办事项用
  def audit_user_ids
    self.category.user_ids.flatten.uniq
  end

  # 厂家直销？
  def cjzx?
    !item.item_type
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    case act
    when "show"
      # 上级单位或者总公司人
      current_u.department.is_ancestors?(self.department_id) || current_u.department.real_ancestry_level(1)
    when "update", "edit" 
      [0,3].include?(self.status) #&& current_u.try(:id) == self.user_id
    when "commit" 
      self.can_opt?("提交") && current_u.try(:id) == self.user_id
    when "update_audit", "audit" 
      self.can_opt?("通过") && self.can_opt?("不通过")
    when "delete", "destroy" 
      self.can_opt?("删除") && current_u.try(:id) == self.user_id
    when "recover", "update_recover" 
      self.can_opt?("下架") && current_u.department.real_ancestry_level(1)
    when "freeze", "update_freeze" 
      self.can_opt?("冻结") && current_u.department.real_ancestry_level(1)
    else false
    end
  end

end
