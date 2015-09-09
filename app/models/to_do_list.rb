# -*- encoding : utf-8 -*-
class ToDoList < ActiveRecord::Base

  has_many :task_queues
	default_scope -> {order(:sort, :id)}
	include AboutStatus

	# 中文意思 状态值 标签颜色 进度 
  def self.status_array
    [
      ["正常",0,"u",100],
      ["已删除",404,"red",0]
    ]
  end

  # 根据不同操作 改变状态
  def change_status_hash
    {
      "删除" => { 0 => 404 }
    }
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='')
    ["delete", "destroy"].include?(act) ? self.can_opt?("删除") : false
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	limited = [404]
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  def self.xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	      <node name='待办事项名称' column='name' class='required' hint='例如：审核注册供应商'/>
	      <node name='列表URL' column='list_url' class='required' hint='例如：/kobe/orders/list 。'/>
	      <node name='审核URL' column='audit_url' class='required' hint='实例id用 $$obj_id$$ 代替，例如：/kobe/orders/$$obj_id$$/audit 。'/>
	      <node name='排序号' column='sort' class='digits' hint='只能输入数字,数字越小排序越靠前'/>
	    </root>
	  }
	end

  # 替换 audit_url 中的 $$obj_id$$
  def get_audit_url(obj_id)
    self.audit_url.gsub("$$obj_id$$",obj_id)
  end

end
