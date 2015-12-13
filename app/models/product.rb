# -*- encoding : utf-8 -*-
class Product < ActiveRecord::Base
	has_many :uploads, class_name: :ProductsUpload, foreign_key: :master_id
	belongs_to :category
  belongs_to :item
  belongs_to :department

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Product") }, foreign_key: :obj_id
  scope :show, -> {where(status: self.effective_status)}

  include AboutStatus

  default_value_for :status, 0

  before_create do
    # 设置rule_id和rule_step
    init_rule
  end
  
  QS = ["category_id_eq", "brand_eq", "sort", "page"]

  # 全文检索
  if Rails.env.production?
    searchable do      
      text :brand, :stored => true, :boost => 10.0
      text :model, :stored => true, :boost => 10.0
      text :version, :stored => true, :boost => 10.0

      text :category do
        category.name if category
      end
      text :department do 
        department.name if department
      end
      integer :department_id
      integer :category_id
      boolean :show
      time :created_at
      time :updated_at
      integer :id
    end
  end

  def self.search(params = {}, options = {})
    options[:page_num] ||= 30
    if options[:all]
      options[:page_num] = Sunspot.search(Product).total
      params[:page] = 1
    end
    options[:show] ||= 1
    conditions = Proc.new{
      fulltext params[:k] do
        highlight :model
        highlight :brand
        highlight :version
      end if params[:k].present?
      with(:show, options[:show]) if options[:show].present?
      order_by :id
      paginate :page => params[:page], :per_page => options[:page_num]
    }
    Sunspot.search(Product, &conditions)
  end

	# 附件的类
  def self.upload_model
    ProductsUpload
  end

  # 总协调人
  def coordinators
    Coordinator.where(department_id: self.department_id, item_id: self.item_id, status: Coordinator.effective_status)
  end

  # 代理商
  def agents
    # item.try(:agents)
    Agent.where(department_id: self.department_id, item_id: self.item_id, status: Agent.effective_status).map(&:agent_dep)
  end

  def show
    self.class.effective_status.include? self.status
  end

  # 产品全称 品牌+型号+版本号
  def name
    "#{self.brand} #{self.model} #{self.version}"
  end

  # 中文意思 状态值 标签颜色 进度 
  def self.status_array
    # [
    #   ["暂存", "0", "orange", 10],
    #   ["正常", "65", "yellow", 100], 
    #   ["等待审核", "8", "blue", 60],
    #   ["审核拒绝", "7", "red", 20],  
    #   ["已下架", "26", "dark", 100],
    #   ["已删除", "404", "dark", 100]
    # ]
    self.get_status_array(["暂存", "正常", "等待审核", "审核拒绝", "已下架", "已删除"])
    # [
    #   ["未提交",0,"orange",10],
    #   ["正常",1,"u",100],
    #   ["等待审核",2,"blue",50],
    #   ["审核拒绝",3,"red",0],
    #   ["已下架",4,"yellow",20],
    #   ["已删除",404,"light",0]
    # ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   status_ha = self.find_step_by_rule.blank? ? 1 : 2
  #   return {
  #     "提交" => { 3 => status_ha, 0 => status_ha },
  #     "通过" => { 2 => 1 },
  #     "不通过" => { 2 => 3 },
  #     "删除" => { 0 => 404 },
  #     "下架" => { 1 => 4 },
  #     "恢复" => { 4 => 1 }
  #   }
  # end

  # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  # 	# 列表中不允许出现的
  # 	limited = [404]
  # 	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

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
      current_u.department.is_ancestors?(self.department_id) || current_u.department.is_zgs?
    when "update", "edit" 
      self.class.edit_status.include?(self.status) #&& current_u.try(:id) == self.user_id
    when "commit" 
      self.can_opt?("提交") && current_u.try(:id) == self.user_id
    when "update_audit", "audit" 
      self.class.audit_status.include?(self.status)
    when "delete", "destroy" 
      self.can_opt?("删除") && current_u.try(:id) == self.user_id
    when "recover", "update_recover" 
      self.can_opt?("恢复") && current_u.department.is_zgs?
    when "freeze", "update_freeze" 
      self.can_opt?("下架") && current_u.department.is_zgs?
    else false
    end
  end

end
