# -*- encoding : utf-8 -*-
class Coordinator < ActiveRecord::Base

  # default_scope -> {order("id desc")}
  belongs_to :item
  belongs_to :department

  default_value_for :status, 65

  include AboutStatus

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [["正常", "65", "yellow", 100], ["已删除", "404", "dark", 100]]
    self.get_status_array(["正常", "已删除"])
    # [
    #   ["正常",0,"u",100],
    #   ["已删除",404,"light",0]
    # ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   {
  #     "删除" => { 0 => 404 }
  #   }
  # end

  # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  #   # 列表中不允许出现的
  #   limited = [404]
  #   arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    case act
    when "show"
      # 上级单位或者总公司人
      current_u.department.is_ancestors?(self.department_id) || current_u.department.is_zgs?
    when "update", "edit"
      self.class.edit_status.include?(self.status) && current_u.try(:id) == self.user_id
    when "delete", "destroy"
      self.can_opt?("删除") && current_u.try(:id) == self.user_id
    else false
    end
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='姓名' column='name' class='required'/>
        <node name='电话' column='tel'/>
        <node name='手机' column='mobile' class='required'/>
        <node name='传真' column='fax'/>
        <node name='电子邮件' column='email' class='email'/>
        <node name='备注' column='summary' data_type='textarea' placeholder='不超过800字'/>
      </root>
    }
  end

end
