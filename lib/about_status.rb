# -*- encoding : utf-8 -*-
module AboutStatus

	include AboutRuleStep

	def self.included(base)
		base.extend ClassMethods
		base.class_eval do 
			scope :status_not_in, lambda { |status| where(["status not in (?) ", status]) }
		end
	end

  # 拓展类方法
 	module ClassMethods

 		# 列表中的状态筛选, 默认404不显示
	  def status_filter(action='')
	  	# 列表中不允许出现的
	    limited = [404]
	  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
	  end

	  # status各状态的中文意思 状态值 标签颜色 进度 
		def status_array
			[
		    ["暂存", 0, "orange", 50],
	      ["等待审核", 1, "orange", 90],
		    ["已发布", 2, "u", 100],
	      ["审核拒绝",3,"red",0],
		    ["已删除", 404, "red", 0]
	    ]
	  end

	  # 获取状态的属性数组 i表示状态数组的维度，0按中文查找，1按数字查找
	  def get_status_attributes(status, i = 0)
	  	arr = self.status_array
	  	return arr.find{|n|n[i] == status}
	  end

	  # 批量改变状态并写入日志 默认状态改变才更新 状态不变不更新
	  def batch_change_status_and_write_logs(id_array,status,stateless_logs,update_params=[],status_change=true)
	  	status = self.get_status_attributes(status)[1] unless status.is_a?(Integer)
	  	update_params << "status = #{status}"
	  	update_params << "logs = replace(IFNULL(logs,'<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root>\n</root>'),'</root>','  #{stateless_logs.gsub('$STATUS$',status.to_s)}\n</root>')"
	    # self.where(id: id_array).where.not(status: [404, status]).update_all("status = #{status}, logs = replace(IFNULL(logs,'<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<root>\n</root>'),'</root>','  #{stateless_logs.gsub('$STATUS$',status.to_s)}\n</root>')")
	    if status_change
	    	self.where(id: id_array).where.not(status: [404, status]).update_all(update_params.join(", "))
	    else # 用于审核转向下一人时 状态不变 但要记录日志
	    	self.where(id: id_array).where.not(status: [404]).update_all(update_params.join(", "))
	    end
	  end

	  # 判断是否树形结构
	  def is_ancestry?
	  	self.attribute_names.include?("ancestry")
	  end

	  # 带图标的动作
	  def icon_action(action,left=true)
	  	key = Dictionary.icons.keys.find{|key|action.index(key)}
	  	icon = key ? Dictionary.icons[key] : Dictionary.icons["其他"]
	  	return left ? "<i class='fa #{icon}'></i> #{action}" : "#{action} <i class='fa #{icon}'></i>"
	  end
	end

	# 根据不同操作 改变状态
  # "提交审核"与action中obj.change_status_and_write_logs一致
  def change_status_hash
    {
      "提交审核" => { 0 => 1 },
      "删除" => { 0 => 404 },
      "通过" => { 1 => 2 },
      "不通过" => { 1 => 3 }
    }
  end

	# 状态标签
	def status_badge(status=self.status)
		arr = self.class.get_status_attributes(status,1)
		if arr.blank?
			str = "<span class='label rounded-2x label-dark'>未知</span>"
		else
			str = "<span class='label rounded-2x label-#{arr[2]}'>#{arr[0]}</span>"
		end
		return str.html_safe
	end

	# 状态进度条
	def status_bar(status=self.status)
		arr = self.class.get_status_attributes(status,1)
		return "" if arr.blank?
		return %Q|
		<span class='heading-xs'>#{arr[0]} <span class='pull-right'>#{arr[3]}%</span></span>
		<div class='progress progress-u progress-xs'>
		<div style='width: #{arr[3]}%' aria-valuemax='100' aria-valuemin='0' aria-valuenow='#{arr[3]}' role='progressbar' class='progress-bar progress-bar-#{arr[2]}'></div>
		</div>|.html_safe
	end

	# 更新状态并写入日志 默认连同孩子节点一起更新 update_subtree
	def change_status_and_write_logs(opt,stateless_logs,update_params=[],update_subtree=true)
		# status = self.class.get_status_attributes(status)[1] unless status.is_a?(Integer)
		# self.update_columns("status" => status, "logs" => logs) unless status == self.status
		status = self.get_change_status(opt)
		if self.class.is_ancestry? && self.has_children? && update_subtree
			# id_array = self.class.self_and_descendants(self.id).status_not_in([404, status]).map(&:id)
			id_array = self.subtree.status_not_in([404, status]).map(&:id)
		else
			id_array = self.id
		end
		self.class.batch_change_status_and_write_logs(id_array,status,stateless_logs,update_params)
	end

	# 根据不同操作 获取需改变的状态 返回数字格式的状态
	def get_change_status(opt)
		if self.class.attribute_method? "change_status_hash"
			status = self.change_status_hash[opt][self.status] # 获取更新后的状态
			return status.present? ? status : self.status
		else
			return opt.is_a?(Integer) ? opt : self.class.get_status_attributes(opt)[1]
		end
	end

	# 根据状态变更判断是否有某个操作
	def can_opt?(opt)
		if self.class.attribute_method? "change_status_hash"
			status = self.change_status_hash[opt][self.status]
			# ["暂存", 0, "orange", 50] 获得 "暂存"
# 			cn_status = self.class.get_status_attributes(self.status, 1)[0] # 当前状态转成中文
# 			status = self.change_status_hash[opt][cn_status] # 获取更新后的状态
			return status.present?
		else
			return false
		end
	end

end
