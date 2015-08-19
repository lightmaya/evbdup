# -*- encoding : utf-8 -*-
module AboutStatus

	def self.included(base)
		base.extend(StatusClassMethods)
		base.class_eval do 
			scope :status_not_in, lambda { |status| where(["status not in (?) ", status]) }
		end
	end

  # 拓展类方法
  module StatusClassMethods
	  # 获取状态的属性数组 i表示状态数组的维度，0按中文查找，1按数字查找
	  def get_status_attributes(status,i=0)
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
			cn_status = self.class.get_status_attributes(self.status,1)[0] # 当前状态转成中文
			status = self.change_status_hash[opt][cn_status] # 获取更新后的状态
			return status.present? ? self.class.get_status_attributes(status)[1] : self.status # 更新后的状态转成数字
		else
			return opt.is_a?(Integer) ? opt : self.class.get_status_attributes(opt)[1]
		end
	end

	# 根据状态变更判断是否有某个操作
	def can_opt?(opt)
		if self.class.attribute_method? "change_status_hash"
			cn_status = self.class.get_status_attributes(self.status,1)[0] # 当前状态转成中文
			status = self.change_status_hash[opt][cn_status] # 获取更新后的状态
			return status.present?
		else
			return false
		end
	end

	# 审核下一步的hash
	def audit_next_hash
		{ "next" => (self.get_next_step.is_a?(Hash) ? "确认并转向上级单位审核" : "确认并结束审核流程"), "return" => "退回发起人", "turn" => "转向本单位下一位审核人" }
	end

	# 判断到哪一步 
  # 返回 rs = {"name"=>"总公司审核", "dep"=>"self.real_ancestry_level(2)","junior"=>[19], "senior"=>[20], "inflow"=>"self.status == 2", "outflow"=>"self.status == 404", "first_audit"=>"单位初审", "last_audit"=>"单位终审"}
  # self.rule_step = start|done|总公司审核|分公司审核 
	# start 表示流程刚开始 根据rule的xml判断到哪一步 
	# 总公司审核|分公司审核 只根据xml的step["name"]判断到哪一步
	# done 表示流程结束 直接返回
	def get_current_step
		return false if !self.class.attribute_method?("rule_step") || !self.class.attribute_method?("rule") || self.rule.blank? || self.rule_step.blank?

		unless self.rule_step == "done"
			rs = self.rule_step == "start" ? self.find_step_by_rule : self.find_step_by_name
		end

		return rs.present? ? rs : self.rule_step
	end

  # 获取下一步操作
  def get_next_step
  	cs = self.get_current_step
  	if cs.is_a?(Hash)
  		step_index = self.get_step_index(cs["name"])
  		if step_index.present?
  			ns = self.find_step_by_rule(step_index + 1)
  			return ns.present? ? ns : 'done'
  		end
  	end
  	return cs
  end

  # 获取步数
  def get_step_index(name)
  	self.rule.get_step_objs.map{ |e| e["name"] }.index(name)
  end

  # 根据rule的xml中step的name判断到哪一步
  def find_step_by_name
  	self.rule.get_step_objs.find{|e| e["name"] == self.rule_step}
  end

  # 根据rule的xml判断到哪一步
  def find_step_by_rule(step_index=0)
  	steps = self.rule.get_step_objs
  	rs = ""
  	steps[step_index..steps.length].each do |step|
      next if eval(step["outflow"]) # 满足 outflow 跳出
      next unless eval(step["inflow"]) # 不满足 inflow 跳出
      next if eval(step["dep"]).blank? # 判断单位是否存在
      rs = step
      break 
    end
    return rs
  end

	# 转向下一个审核人的json
	def turn_next_user_json(current_u)
		rs = self.get_current_step
		nodes = []
		if rs.is_a?(Hash)
    	# rs["dep"]是real_ancestry相同的数组，因此只需取第一个单位的real_users（所有的用户）
    	deps = eval(rs["dep"])
    	if deps.present?
	    	deps.first.real_users.each do |user| 
	    		next if current_u.id == user.id
	    		next if (user.menu_ids & (rs["junior"] | rs["senior"])).blank?
	    		audit_type = (user.menu_ids & rs["senior"]).present? ? "确认审核" : "普通审核"
	    		nodes << %Q|{ "id": "u_#{user.id}", "pId": #{user.department.id}, "name": "#{user.name}[#{audit_type}]" }|
	    		((user.department.ancestors << user.department) & deps).each{ |e| nodes << %Q|{ "id": #{e.id}, "pId": #{e.parent_id}, "name": "#{e.name}", "isParent":true, "open":true }| }
	    	end
	    end
    end
    return nodes.uniq
	end


	# 插入待办事项
	def create_task_queue(user_id='')
		rs = self.get_current_step
		tqs = []
		if rs.is_a?(Hash)
			if user_id.blank?
	      # 没有指定user_id时，只有初审的人插入待办事项
	      rs["junior"].each do |m|
	      	tqs << TaskQueue.create(class_name: self.class, obj_id: self.id, menu_id: m)
	      end
	    else
	    	user = User.find_by(id: user_id)
	    	if (user.menu_ids & (rs["junior"] | rs["senior"])).present?
	    		tqs << TaskQueue.create(class_name: self.class, obj_id: self.id, user_id: user_id)
	    	end
	    end
	    if tqs.present? # 删除旧的待办事项
	    	self.delete_task_queue(tqs.map(&:id))
	    end
	  else
			if rs == 'done' # 流程结束 删除所有待办事项
				self.delete_task_queue
			end
		end
	end

	# 删除待办事项
	def delete_task_queue(except_id=[])
		delete_id = TaskQueue.where(class_name: self.class,obj_id: self.id)
		delete_id = delete_id.where.not(id: except_id) if except_id.present?
		TaskQueue.destroy(delete_id) if delete_id.present?
	end

end