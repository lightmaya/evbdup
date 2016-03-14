# -*- encoding : utf-8 -*-
class AssetProject < ActiveRecord::Base
  default_scope -> {order("id desc")}
  belongs_to :department
  has_many :items, class_name: :AssetProjectItem

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "AssetProject") }, foreign_key: :obj_id

  default_value_for :status, 0

  include AboutStatus

  before_create do
    # 设置rule_id和rule_step
    init_rule
  end

  after_create do
    create_no(rule.code, "sn")
  end

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [
    #   ["暂存", "0", "orange", 10],
    #   ["已生效", "72", "yellow", 100],
    #   ["等待审核", "8", "blue", 60],
    #   ["审核拒绝", "7", "red", 20],
    #   ["已删除", "404", "dark", 100]]
    self.get_status_array(["暂存", "已生效", "等待审核", "审核拒绝", "已删除"])
    # [
    #   ["未提交",0,"orange",10],
    #   ["已完成",1,"u",100],
    #   ["等待审核",2,"blue",50],
    #   ["审核拒绝",3,"red",0],
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
  #     "删除" => { 0 => 404 }
  #   }
  # end

  # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  #   # 列表中不允许出现的
  #   limited = [404]
  #   arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

  # 流程图的开始数组
  def step_array
    arr = ["录入", "提交"]
    arr |= self.get_obj_step_names
    return arr
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
       <node name='项目名称' column='name' class='required'/>
       <node name='报销日期' column='deliver_at' class='required date_select dateISO'/>
       <node name='单位名称' column='dep_name' class='required'/>
       <node name='单位联系人' column='dep_man'  class='required'/>
       <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
       <node column='total' data_type='hidden'/>
     </root>
   }
  end

end
