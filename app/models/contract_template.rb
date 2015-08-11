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
	      <node name='内容' column='content' data_type='textarea' class='required'/>
	    </root>
	  }
	end

	def cando_list(can_opt_arr=[])
    return "" if can_opt_arr.blank?
    arr = [] 
    # 查看
    arr << [self.class.icon_action("详细"), "/kobe/contract_templates/#{self.id}", target: "_blank"]  if can_opt_arr.include?(:read)
    # 修改
    arr << [self.class.icon_action("修改"), "/kobe/contract_templates/#{self.id}/edit"] if can_opt_arr.include?(:update)
    # 删除
    arr << [self.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{self.class.icon_action('删除')}", '/kobe/contract_templates/#{self.id}/delete', "#opt_dialog") }] if can_opt_arr.include?(:update_destroy)
    return arr
  end

  # 文件夹的完整路径
  def full_dir_path
  	File.join(Rails.root, "app/views", self.url)
  end

  # 文件的完整路径
  def full_file_path
  	File.join(self.full_dir_path, "_#{self.file_name}.html.erb")
  end

  # 文件夹是否存在 如果不存在生成文件夹
	def dir_exists?
  	if File::directory?(self.full_dir_path)
  		return true
  	else
  		Dir.mkdir(self.full_dir_path)
  		self.dir_exists?
  	end
	end

	# 生成文件
	def create_file
		if self.dir_exists?
			file = File.open(self.full_file_path, "w")
    	file.puts self.content
		  file.close
  	end
	end

	def self.tips
    msg = []
    msg << "合同模板内容中需添加数据表格时，请用 <%= render :partial => '/kobe/orders/ht/table', :locals => { :myform => @ms_form } %> 代替"
  end

end
