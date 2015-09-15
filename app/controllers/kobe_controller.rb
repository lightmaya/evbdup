# -*- encoding : utf-8 -*-
class KobeController < ApplicationController
  before_action :request_signed_in!
  before_action :init_themes
  # cancancan验证 如果有before_action cancancan放最后
  load_and_authorize_resource
  skip_before_action :verify_authenticity_token, only: ["commit", "read"]

  def index
    # @user = current_user
    # UserMailer.registration_confirmation(@user).deliver
    # render :text => "sdfsdfsdf"
  end

  def test
    Setting.audit_money = {"汽车采购" => 180000, "办公小额" => 3000}
    @tmp = "
    <p>读取字典数据（静态配置信息）：#{Dictionary.company_name}</p>
    <br/>
    <p>读取设置数据（动态配置信息）：#{Setting.audit_money["汽车采购"].to_s}</p>
    <br/>
    <p>默认时间格式：#{Time.new.to_s}</p>
    <br/>
    <p>中文时间格式：#{Time.new.to_s(:cn_time)}</p>"
    @city = Area.find(1)
  end

  # 类模型的json格式，tree_select使用
  def obj_class_json
    obj_class = params[:obj_class]
    if obj_class.blank?
      str = '[]'
    else
      begin
        # str = obj_class.constantize.get_json(params[:name])
      rescue 
        str = '[]'
      end
    end
    return render :json => str
  end
  
  # 以下是公用方法
  protected

  # 树节点移动
  def ztree_move(obj_class)
    # render :text => obj_class.ztree_move_node(params[:sourceId],params[:targetId],params[:moveType],params[:isCopy])
    logs = obj_class.ztree_move_node(params[:sourceId],params[:targetId],params[:moveType],params[:isCopy])
    write_logs(obj_class.find_by(id: params[:sourceId]), "移动",logs)
    render :text => "targetId=#{params[:targetId]},sourceId=#{params[:sourceId]},moveType=#{params[:moveType]},isCopy=#{params[:isCopy]}"
  end

  # 以下是私有方法
  private 
  
  # 准备主界面的素材 ---- #未读短信息
  def init_themes
    # @unread_notifications = current_user.unread_notifications
    @suggestion_form = SingleForm.new(Suggestion.xml,Suggestion.new,{upload_files: true, grid: 1, form_id: "suggestion_form", action: kobe_suggestions_path})
  end

  # 获取列表的查询条件,arr应该是一个二维数组,类似于[["name = ? ", "xxx"],["user_id = ? ",11]]
  def get_conditions(table_name,arr=[])
    # 列表标题栏筛选的条件
    filter_arr = head_filter(table_name)
    arr = arr | filter_arr
    unless arr.blank?
      keys = []
      arr.each{|a| 
        keys << a.delete_at(0)
      }
      return arr.flatten!.unshift(keys.join(" and "))
    else 
      return []
    end
  end

  # 列表标题栏的筛选
  def head_filter(table_name)
    arr = []
    unless params[:status_filter].blank? || params[:status_filter] == "all"
      arr << ["#{table_name}.status = ?", params[:status_filter].to_i]
    end 
    unless params[:date_filter].blank? || params[:date_filter] == "all"
      arr << ["#{table_name}.created_at >= ?", translate_cn_date(params[:date_filter])]
    end
    return arr
  end

  # 翻译日期,数据来源参照kobe_helper的date_filter方法
  def translate_cn_date(d)
    case d
    when "3m"
      return Time.now.midnight - 3.month
    when "6m"
      return Time.now.midnight - 6.month
    when "1y"
      return Time.now.midnight - 1.year
    when "ty"
      return Time.now.beginning_of_year
    end
  end

  # 自定义条件判断没有某权限的提示
  def cannot_do_tips(msg=Dictionary.tips.custom_default_cannot)
    raise CanCan::AccessDenied.new(msg) 
  end

  # 审核提示
  def audit_tips
    cannot_do_tips(Dictionary.tips.audit_default_cannot)
  end

  # 生成审核日志
  def create_audit_logs(obj)
    cs = obj.get_current_step
    act = cs.is_a?(Hash) ? cs["name"] : "审核#{params[:audit_yijian]}"
    opt = obj.audit_next_hash[params[:audit_next]]
    opt << "：#{params[:audit_next_user]}" if params[:audit_next] == "turn"
    return stateless_logs(act,"审核#{params[:audit_yijian]}，#{opt}。审核理由：#{params[:audit_liyou]}", false)
  end

  # 审核的下一步操作 确认并转向上级单位审核、确认并结束审核流程
  def go_to_audit_next(obj)
    logs = create_audit_logs(obj)
    cs = obj.get_current_step
    if cs.is_a?(Hash)
      ns = obj.get_next_step
      if ns.is_a?(Hash) # 确认并转向上级单位审核 状态不变 rule_step改变
        rule_step = ns["name"]
        obj.class.batch_change_status_and_write_logs(obj.id,obj.status,logs,["rule_step = '#{rule_step}'"],false)
      else # 确认并结束审核流程 状态改变 rule_step改变
        obj.change_status_and_write_logs(params[:audit_yijian],logs,["rule_step = '#{ns}'"],false) if ns == "done"
      end
    end
    # 插入待办事项
    obj.reload.create_task_queue
  end

  # 审核 退回发起人 状态改变 rule_step改变
  def go_to_audit_return(obj)
    logs = create_audit_logs(obj)
    obj.change_status_and_write_logs(params[:audit_yijian],logs,["rule_step = null"],false)
    # 删除待办事项
    obj.reload.delete_task_queue
    # 发送站内消息
    
  end

  # 审核 转向下一人 状态不变 rule_step不变
  def go_to_audit_turn(obj)
    logs = create_audit_logs(obj)
    obj.class.batch_change_status_and_write_logs(obj.id,obj.status,logs,[],false)
    # 插入待办事项
    obj.reload.create_task_queue(params[:audit_next_user_id].split("_")[1])
  end

  # 审核 1.更新rule_step、status、logs 2.插入待办事项
  def save_audit(obj)
    eval("go_to_audit_#{params[:audit_next]}(obj)")
    tips_get("审核#{params[:audit_yijian]}，审核理由：#{params[:audit_liyou]}")
  end

  # 是否有审核权限
  def can_audit?(obj,menu_ids=[])
    return false unless obj.get_rule_dep.present? && obj.get_rule_dep.id == current_user.department.real_dep.id
    if obj.task_queues.present?
      tq = obj.task_queues
      # user_id 不为空时 取当前用户的id
      return true if tq.find{ |e| e.user_id == current_user.id }.present?
      # menu_id 不为空时 判断当前用户的menu_ids与传过来的审核menu_ids的交集 有交集就可以审核
      return true if menu_ids.present? && tq.find{ |e| menu_ids.include?(e.menu_id) && (current_user.menu_ids & menu_ids).present? }.present?
    end
    return false
  end

end
