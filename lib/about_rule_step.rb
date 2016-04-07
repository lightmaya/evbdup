# -*- encoding : utf-8 -*-
module AboutRuleStep

  # before_create时初始化rule_id和rule_step
  def init_rule
    self.rule_id = Rule.find_by(yw_type: self.class.to_s).try(:id)
    self.rule_step = 'start'
  end

  # 提交时需更新的参数 主要用于更新rule_step
  # 返回 change_status_and_write_logs(opt,stateless_logs,update_params=[]) 的update_params 数组
  def commit_params
    arr = []
    arr << (self.find_step_by_rule.blank? ? "rule_step = 'done'" : "rule_step = 'start'")
    return arr
  end

  # 审核下一步的hash
  def audit_next_hash
    # 确认并结束当前流程（如需上级单位审核则自动转向上级单位。）
    { "next" => (self.get_next_step.is_a?(Hash) ? "确认并转向上级单位审核" : "确认并结束审核流程"), "return" => "退回发起人", "turn" => "转向本单位下一位审核人" }
  end

  # 判断到哪一步
  # 返回 rs = {"name"=>"总公司审核", "dep"=>"self.real_ancestry_level(2)","junior"=>[19], "senior"=>[20], "inflow"=>"self.status == 2", "outflow"=>"self.status == 404", "first_audit"=>"单位初审", "last_audit"=>"单位终审", "to_do_id"=>"1"}
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

  # 获取上一步操作
  def get_prev_step
    cs = self.get_current_step
    if cs.is_a?(Hash)
      step_index = self.get_step_index(cs["name"])
      if step_index > 0
        ns = self.find_step_by_rule(step_index - 1)
        return ns.present? ? ns : 'start'
      end
    end
    return "start"
  end

  # 获取步数
  def get_step_index(name)
    self.get_obj_step_names.index(name)
  end

  # 根据rule的xml中step的name判断到哪一步
  def find_step_by_name
    self.get_obj_steps.find{|e| e["name"] == self.rule_step}
  end

  # 根据rule的xml判断到哪一步
  def find_step_by_rule(step_index=0)
    steps = self.get_obj_steps
    return steps.present? ? steps[step_index] : ""
    # rs = ""
    # steps[step_index..steps.length].each do |step|
    #    next if eval(step["outflow"]) # 满足 outflow 跳出
    #    next if eval(step["dep"]).blank? # 判断单位是否存在
    #    next unless eval(step["inflow"]) # 不满足 inflow 跳出
    #    rs = step
    #    break
    #  end
    #  return rs
  end

  # 转向下一个审核人的json
  def turn_next_user_json(current_u)
    rs = self.get_current_step
    nodes = []
    if rs.is_a?(Hash)
      dep = eval(rs["dep"])
      if dep.present?
        dep.real_users.each do |user|
          next if current_u.id == user.id
          next if (user.menu_ids & (rs["junior"] | rs["senior"])).blank?
          audit_type = (user.menu_ids & rs["senior"]).present? ? "确认审核" : "普通审核"
          nodes << %Q|{ "id": "u_#{user.id}", "pId": #{user.department.id}, "name": "#{user.name}[#{audit_type}]" }|
          ((user.department.ancestors << user.department) & dep.subtree).each{ |e| nodes << %Q|{ "id": #{e.id}, "pId": #{e.parent_id}, "name": "#{e.name}", "isParent":true, "open":true }| }
        end
      end
    end
    return nodes.uniq
  end

  # 获取审核单位 用在待办事项和审核 判断有没有审核权限
  def get_rule_dep
    cs = self.get_current_step
    return cs.is_a?(Hash) ? eval(cs["dep"]) : nil
  end

  # 插入待办事项
  def create_task_queue(user_id='')
    rs = self.get_current_step
    tqs = []
    if rs.is_a?(Hash)
      to_do_id = rs["to_do_id"]
      dep = eval(rs["dep"])
      if user_id.blank?
        rs["junior"].each do |m|
          if dep.is_a?(Array)
            dep.each{ |d| tqs << create_tq_without_user_id(d, m, to_do_id) }
          else
            tqs << create_tq_without_user_id(dep, m, to_do_id)
          end
        end
      else
        user = User.find_by(id: user_id)
        if user.present? && (user.menu_ids & (rs["junior"] | rs["senior"])).present?
          tqs << TaskQueue.create(class_name: self.class, obj_id: self.id, user_id: user_id, to_do_list_id: to_do_id, dep_id: dep.id)
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

  # 插入待办事项 没有指定user_id
  def create_tq_without_user_id(dep, menu_id, to_do_list_id)
    # 没有指定user_id时，判断当前审核用户有没有关联品目（判断有没有audit_user_ids和current_step_users交集）
    current_step_users = dep.real_users.map(&:id)
    if self.class.attribute_method?("audit_user_ids") && (current_step_users & self.audit_user_ids).present?
      (current_step_users & self.audit_user_ids).each do |u_id|
        return TaskQueue.create(class_name: self.class, obj_id: self.id, menu_id: menu_id, user_id: u_id, to_do_list_id: to_do_list_id, dep_id: dep.id)
      end
    else
      # 没有audit_user_ids，只有初审的人插入待办事项
      return TaskQueue.create(class_name: self.class, obj_id: self.id, menu_id: menu_id, to_do_list_id: to_do_list_id, dep_id: dep.id)
    end
  end

  # 删除待办事项
  def delete_task_queue(except_id=[])
    delete_id = TaskQueue.where(class_name: self.class,obj_id: self.id)
    delete_id = delete_id.where.not(id: except_id) if except_id.present?
    TaskQueue.destroy(delete_id.map(&:id)) if delete_id.present?
  end

  # 获取该实例rule的所有步骤 如返回数组为空 表示不需要审核
  def get_obj_steps
    arr = []
    self.rule.get_step_objs.each do |step|
      next if eval(step["outflow"]) # 满足 outflow 跳出
      next if eval(step["dep"]).blank? # 判断单位是否存在
      next unless eval(step["inflow"]) # 不满足 inflow 跳出
      arr << step
    end
    return arr
  end

  # 该实例rule的步骤名称
  def get_obj_step_names
    self.get_obj_steps.map{ |e| e["name"] }
  end

  # 判断当前步骤在数组中的位置 返回整数
  def get_current_step_in_array(array=[])
    return 0 if array.blank?
    current_index = 0
    steps = self.get_obj_step_names
    # 如果有流程按流程判断
    if steps.present?
      if self.rule_step == "done"
        index = array.index(steps.last) + 1
        current_index = index if index.present?
      end
      cs = self.get_current_step
      # 先判断rule_step
      # return array.length - 1 if cs == 'done'
      if cs.is_a?(Hash)
        index = array.index(cs["name"])
        return index if index.present?
      end
      # 不在定制的rule里 包括rule_step == "done" 都取最后一条日志的操作内容在数组中的位置+1
      node = self.get_last_node_by_logs
      if node.present?
        opt = node.attributes["操作内容"].to_str
        index = array.index(opt)
        if index.present? && current_index <= index
          # 如果是退回发起人 rule_step=null
          current_index = (self.rule_step.blank? && steps.index(opt)) ? array.index(steps[0])-1 : index+1
        end
      end
    else
      # 如果没有流程按日志判断
      log_names = Nokogiri::XML(self.logs).css("node").map{|n|n["操作内容"] }
      tmp_arr = array & log_names
      if tmp_arr.blank?
        current_index = log_names.present? ? 1 : 0
      else
        tmp_arr.each do |a|
          current_index = [array.index(a), current_index].max
        end
      end
    end
    return current_index == array.length - 1 ? array.length : current_index
  end

  # 获取日志中的最后一条记录 node_attr 可以指定node的attributes自带[] 例如 node_attr="[操作内容='下单']"
  def get_last_node_by_logs(node_attr='')
    doc = Nokogiri::XML(self.logs)
    return node_attr.present? ? doc.css("node#{node_attr}").last : doc.css("node").last
  end

end
