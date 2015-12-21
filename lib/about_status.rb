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
    # 无效的完结状态
    def finish_status
      (Dictionary.all_status_array.select{ |e| (e[1] % 7 == 5) } & self.status_array).map{ |e| e[1] }
    end

    # 审核状态
    def audit_status
      (Dictionary.all_status_array.select{ |e| (e[1] % 7 == 1) } & self.status_array).map{ |e| e[1] }
    end

    # 有效的状态
    def effective_status
      (Dictionary.all_status_array.select{ |e| (e[1] % 7 == 2) } & self.status_array).map{ |e| e[1] }
    end

    # 自动生效的有效状态
    def auto_effective_status
      (Dictionary.all_status_array.select{ |e| [16, 72, 51, 65, 2].include? e[1] } & self.status_array).map{ |e| e[1] }
    end

    # 可以修改的状态 包括有效状态
    def edit_status
      return only_edit_status | edit_and_effective_status
    end

    # 可以修改的状态 不包括有效状态下也可以修改
    def only_edit_status
      (Dictionary.all_status_array.select{ |e| (e[1] % 7 == 0) } & self.status_array).map{ |e| e[1] }
    end

    # 有效状态可以修改
    def edit_and_effective_status
      (Dictionary.all_status_array.select{ |e| [51, 65].include? e[1] } & self.status_array).map{ |e| e[1] }
    end

    # 列表中的状态筛选, 默认404不显示
    def status_filter(arr = [])
      # 列表中不允许出现的
      arr = [404] if arr.blank?
      limited = arr
      arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
    end

    # 在application中的所有状态中，获取每个model中所需要的状态
    def get_status_array(arr=[])
      Dictionary.all_status_array.select{ |e| arr.include? e.first }
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
    if self.class.attribute_method?("change_status_hash") && self.change_status_hash[opt].present?
      status = self.change_status_hash[opt][self.status] # 获取更新后的状态
      return status.present? ? status : self.status
    else
      return opt.is_a?(Integer) ? opt : self.class.get_status_attributes(opt)[1]
    end
  end

  # 根据状态变更判断是否有某个操作
  def can_opt?(opt)
    if self.class.attribute_method? "change_status_hash"
      return false if self.change_status_hash[opt].blank?
      status = self.change_status_hash[opt][self.status]
      # ["暂存", 0, "orange", 50] 获得 "暂存"
      # 			cn_status = self.class.get_status_attributes(self.status, 1)[0] # 当前状态转成中文
      # 			status = self.change_status_hash[opt][cn_status] # 获取更新后的状态
      return status.present?
    else
      return false
    end
  end

  # 根据不同操作 改变状态
  def change_status_hash
    ha = {
      "删除" => { 0 => 404, 65 => 404 },

      "下架" => { 65 => 26 },
      "冻结" => { 65 => 12 },
      "停止" => { 65 => 68 },
      "恢复" => { 12 => 65, 26 => 65, 68 => 65 },

      "回复" => { 58 => 75 }
    }

    auto_status = self.class.auto_effective_status.first
    ha["提交"] = { 0 => auto_status, 7 => auto_status, 14 => 16 } if auto_status.present?

    if self.class.attribute_method? "rule"
      cs = self.get_current_step
      rs = cs.is_a?(Hash) ? cs : self.find_step_by_rule
      if rs.present?
        start_status = rs["start_status"].to_i
        return_status = rs["return_status"].to_i
        ns = self.get_next_step
        finish_status = ns.is_a?(Hash) ? ns["start_status"].to_i : rs["finish_status"].to_i
        # 如果当前状态是修改状态，提交后变成开始某流程步骤的状态 start_status
        ha["提交"] = { self.status => start_status } if self.class.only_edit_status.include? self.status
        # 通过本步骤 状态转向 下一步的开始状态 如果没有下一步则是本部的结束状态
        ha["通过"] = { start_status => finish_status, 10 =>  finish_status, 42 => finish_status }
        # 不通过 状态转向 本步的退回状态
        ha["不通过"] = { start_status => return_status, 10 =>  return_status, 42 => return_status }

        # 网上竞价选择中标人
        ha["选择中标人"] = { self.class.bid_and_choose_status => start_status } if self.class == BidProject
      end
    end
    return ha
    # {
    #   "提交" => { 0 => [16, 8, 72, 15, 51, 65, 2], 7 => [16, 8, 72, 51, 65, 2],  14 => [15, 16] },

    #   # 审核、买方卖方确认
    #   "通过" => { 8 => [16, 72, 51, 65, 9], 15 => [16], 22 => [23], 29 => [33], 3 => [4, 8], 4 => [8], 36 => [35], 43 => [47] },
    #   "不通过" => { 8 => [7], 15 => [14], 22 => [21], 29 => [28], 3 => [42], 4 => [10], 36 => [37], 43 => [44] },

    #   "确定中标人" => { 16 => 22 },
    #   "废标" => { 16 => 29},

    # "删除" => { 0 => 404, 65 => 404 },

    # "下架" => { 65 => 26 },
    # "冻结" => { 65 => 12 },
    # "停止" => { 65 => 68 },

    # "恢复" => { 12 => 65, 26 => 65, 68 => 65 },

    # "回复" => { 58 => 75 }
    # }
  end

end
