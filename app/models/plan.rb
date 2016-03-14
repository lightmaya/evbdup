# -*- encoding : utf-8 -*-
class Plan < ActiveRecord::Base
  has_many :uploads, class_name: :PlanUpload, foreign_key: :master_id
  has_many :products, class_name: :PlanProduct
  # default_scope -> {order("id desc")}
  belongs_to :category
  belongs_to :plan_item
  belongs_to :department

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Plan") }, foreign_key: :obj_id

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
    PlanUpload
  end

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [
    #   ["暂存", "0", "orange", 10], ["审核通过", "9", "yellow", 70],
    #   ["等待审核", "8", "blue", 60], ["审核拒绝", "7", "red", 20],
    #   ["自动生效", "2", "yellow", 70],  ["已删除", "404", "dark", 100]
    # ]
    self.get_status_array(["暂存", "审核通过", "等待审核", "审核拒绝", "自动生效", "已删除"])
    # [
    #   ["未提交",0,"orange",10],
    #   ["审核通过",1,"u",100],
    #   ["等待审核",2,"blue",50],
    #   ["审核拒绝",3,"red",0],
    #   ["自动生效",5,"yellow",100],
    #   ["已删除",404,"light",0]
    # ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   status_ha = self.find_step_by_rule.blank? ? 5 : 2
  #   return {
  #     "提交" => { 3 => status_ha, 0 => status_ha },
  #     "通过" => { 2 => 1 },
  #     "不通过" => { 2 => 3 },
  #     "删除" => { 0 => 404 }
  #   }
  # end

  # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  # 	# 列表中不允许出现的
  # 	limited = [404]
  # 	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

  # 根据品目判断审核人 插入待办事项用
  def audit_user_ids
    self.category.user_ids.flatten.uniq
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    case act
    when "show"
      current_u.real_department.is_ancestors?(self.department_id)
    when "update", "edit"
      self.class.edit_status.include?(self.status) && current_u.try(:id) == self.user_id
    when "commit"
      self.can_opt?("提交") && current_u.try(:id) == self.user_id
    when "update_audit", "audit"
      self.class.audit_status.include?(self.status)
    when "delete", "destroy"
      self.can_opt?("删除") && current_u.try(:id) == self.user_id
    else false
    end
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='计划名称' column='name' class='required' hint='例如：****直属库2015年输送机采购计划'/>
        <node name='采购单位' column='dep_name' class='required' display='readonly'/>
        <node name='联系人' column='dep_man' class='required'/>
        <node name='联系人座机' column='dep_tel' class='required'/>
        <node name='联系人手机' column='dep_mobile' class='required'/>
        <node name='所在地区' class='tree_radio required' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"Area"}' partner='area_id'/>
        <node column='area_id' data_type='hidden'/>
        <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
        <node column='total' data_type='hidden'/>
      </root>
    }
  end

end
