# -*- encoding : utf-8 -*-
class ContractTemplate < ActiveRecord::Base

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
      "删除" => { "正常" => "已删除" }
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
	      <node name='文件名' column='file_name' class='required' hint='英文的文件名，用于打印时系统自动选择合同模板。例如：common。'/>
	      <node name='模板名称' column='name' class='required' hint='中文的模板名称，用于对应品目的合同模板的选择。例如：普通模版、汽车模板。'/>
	      <node name='模板文件URL' column='url' class='required' hint='存放模板的文件夹路径，例如：/kobe/orders/ht 。'/>
	    </root>
	  }
	end

end
