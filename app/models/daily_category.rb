# -*- encoding : utf-8 -*-
class DailyCategory < ActiveRecord::Base
  validates_with MyValidator

  # default_scope -> {order(:ancestry, :sort, :id)}

  include AboutStatus
  include AboutAncestry

  default_value_for :status, 65

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [["正常", "65", "yellow", 100], ["已删除", "404", "dark", 100]]
    self.get_status_array(["正常", "已删除"])
		# [
	 #    ["正常",0,"u",100],
	 #    ["已删除",404,"red",100]
  #   ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   {
  #     "删除" => { 0 => 404 }
  #   }
  # end

  # 根据action_name 判断obj有没有操作
  def cando(act='')
    ["delete", "destroy"].include?(act) ? self.can_opt?("删除") : false
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  # 	# 列表中不允许出现的
  # 	limited = [404]
  # 	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='父节点名称'  display='disabled'/>
        <node name='parent_id' data_type='hidden'/>
        <node name='名称' column='name' class='required' rules='{ remote: { url:"/kobe/daily_categories/valid_name", type:"post" }}'/>
        <node name='排序号' column='sort' class='digits' hint='只能输入数字,数字越小排序越靠前'/>
      </root>
    }
  end
end
