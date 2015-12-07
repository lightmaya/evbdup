# -*- encoding : utf-8 -*-
class PlanItem < ActiveRecord::Base

  has_many :plan_item_categories, dependent: :destroy
  has_many :categories, through: :plan_item_categories

  # default_scope -> {order("id desc")}

  before_save do 
    self.category_ids = self.categoryids.split(",")
  end

  include AboutStatus

  default_value_for :status, 0

  # 中文意思 状态值 标签颜色 进度 
  def self.status_array
    # [
    #   ["暂存", "0", "orange", 10], 
    #   ["正常", "65", "yellow", 100], 
    #   ["已过期", "54", "dark", 100], 
    #   ["已删除", "404", "dark", 100]
    # ]
    self.get_status_array(["暂存", "正常", "已过期", "已删除"])
    # [
    #   ["暂存",0,"orange",10],
    #   ["有效",1,"blue",100],
    #   ["已过期",2,"red",50],
    #   ["已删除",404,"light",0]
    # ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   {
  #     "提交" => { 0 => 1 },
  #     "停止" => { 1 => 2 },
  #     "删除" => { 0 => 404 }
  #   }
  # end

  # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  #   # 列表中不允许出现的
  #   limited = [404]
  #   arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

  def cando(act='',current_u=nil)
    case act
    when "update", "edit" 
      self.class.edit_status.include?(self.status)
    when "commit" 
      self.can_opt?("提交")
    when "delete", "destroy" 
      self.can_opt?("删除")
    when "add_plan" 
      self.class.effective_status.include?(self.status) && self.end_time > Time.now
    else false
    end
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='计划名称' column='name' class='required'/>
        <node name='上报截止时间' column='end_time' class='datetime_select required datetime'/>
        <node name='品目' class='tree_checkbox required' json_url='/kobe/shared/category_ztree_json' partner='categoryids'/>
        <node column='categoryids' data_type='hidden'/>
      </root>
    }
  end

end
