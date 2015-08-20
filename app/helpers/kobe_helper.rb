# -*- encoding : utf-8 -*-
module KobeHelper

  # 日期筛选,用于list列表页面
  def date_filter(arr=[])
    if arr.blank?
      arr = [
        ["最近三个月","3m"],
        ["最近半年","6m"],
        ["最近一年","1y"],
        ["今年以内","ty"],
        ["全部时间","all"]
      ]
    end
    return head_filter("date_filter",arr)
  end

  # 状态筛选,用于list列表页面
  def status_filter(model,action='')
    arr = model.status_filter(action).push(["全部状态","all"])
    return head_filter("status_filter",arr)
  end

  # 更多操作,用于list列表页面,主要指批量操作的下拉按钮
  # 也可设置多个按钮组,例如增加和更多操作两个按钮 btn_count=2
  def more_actions(arr,btn_count=1)
    btn_count = btn_count.to_i unless btn_count.is_a?(Integer)
    str = ""
    if btn_count > 1
      str << btn_group(arr[0...btn_count-1], false)
      arr = arr[btn_count-1, arr.length]
    end
    str << head_filter("more_actions",arr.push(["更多操作", "all"]))
    return raw str.html_safe
  end

  # 树形结构的右键菜单 默认增加、修改、删除、冻结、恢复,can_opt_action对应cancancan验证的action
  def ztree_right_btn(model_name='')
    return '' if model_name.blank?
    str = ""
    default_ztree_opt = []
    default_ztree_opt << {onclick_func: "addTreeNode();", icon_class: "icon-plus", opt_name: "增加", can_opt_action: "create"}
    default_ztree_opt << {onclick_func: "editTreeNode();", icon_class: "icon-wrench", opt_name: "修改", can_opt_action: "update"}
    default_ztree_opt << {onclick_func: "removeTreeNode();", icon_class: "icon-trash", opt_name: "删除", can_opt_action: "update_destroy"}
    default_ztree_opt << {onclick_func: "freezeTreeNode();", icon_class: "icon-ban", opt_name: "冻结", can_opt_action: "update_freeze"}
    default_ztree_opt << {onclick_func: "recoverTreeNode();", icon_class: "icon-action-undo", opt_name: "恢复", can_opt_action: "update_recover"}
    opt = current_user.can_option_hash[model_name]
    if opt.present?
      opt.each do |opt|
        ha = default_ztree_opt.find{|d| d[:can_opt_action] == opt.to_s}
        if ha.present?
          str << %Q{
            <button class='btn' style="font-size:12px;" onclick="#{ha[:onclick_func]}">
              <i class='#{ha[:icon_class]}'></i> #{ha[:opt_name]}
            </button>
          }
        end
      end
    end
    return raw str.html_safe
  end

  # 审核下一步
  def audit_next_step(obj, yijian='通过')
    # ha = { "next" => (obj.get_next_step.is_a?(Hash) ? "确认并转向上级单位审核" : "确认并结束审核流程"), "return" => "退回发起人", "turn" => "转向本单位下一位审核人" }
    ha = obj.audit_next_hash 
    str = ""
    step = yijian == "通过" ? (current_user.has_option?(obj.class.to_s, :last_audit) ? "next" : "") : "return"
    str << audit_next_step_label(step, ha[step]) if step.present?
    str << content_tag(:div, audit_next_step_label("turn", ha["turn"]).html_safe, :class=>'inline-group')
    return str.html_safe
  end

  # 审核下一步的label 标签 
  def audit_next_step_label(key,value)
    %Q{ <label class="radio"><input type="radio" name="audit_next" value="#{key}"><i class="rounded-x"></i> #{value}</label> }
  end

  def audit_reason_modal(get_audit_reason_arr=[])
    str = "<div class='sky-form'><fieldset><section>"
    get_audit_reason_arr.each do |reason|
      str << %Q{ <label class="radio"><input type="radio" name="default_audit_reason" value="#{reason}"><i class="rounded-x"></i> #{reason}</label> }
    end
    str << "</section></fieldset></div>"
    return str.html_safe
  end
  
  # 待办事项显示
  # 当前用户有超过10条的待办事项 用list方式显示 不足10条全部显示
  def show_to_do_list
    str = ""
    if current_user.to_do_count > 10
      current_user.to_do_list.each_with_index do |obj, index|
        title = %Q|
          #{ link_to obj.to_do_list.name, obj.to_do_list.list_url }
          <span class="label rounded-2x label-red">#{obj.num}</span>
        |
        desc = "暂时忽略 <i class='fa fa-minus-circle'></i>"
        str << show_to_do_div(title,desc,index)
      end
    else
      current_user.to_do_all.each_with_index do |obj, index|
        title = link_to obj.get_belongs_to_obj.try(:name), obj.to_do_list.audit_url.gsub("$$obj_id$$",obj.obj_id.to_s)
        desc = "来自 #{obj.to_do_list.name} <i class='fa fa-check-circle'></i>"
        str << show_to_do_div(title,desc,index)
      end
    end
    return str.html_safe
  end

  # 显示一条待办事项的div
  def show_to_do_div(title,desc,index)
    return %Q|
      <div class="profile-post color-#{index%7+1}">
        <span class="profile-post-numb">#{sprintf("%02d",index+1)}</span>
        <div class="profile-post-in">
            <h3 class="heading-xs">#{title}</h3>
            <p>#{desc}</p>
        </div>
      </div>
    |.html_safe
  end

end