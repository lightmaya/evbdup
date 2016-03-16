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
  def status_filter(model, action='')
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

  # 树形结构的右键菜单 默认增加、修改、删除、冻结、恢复
  def ztree_right_btn(model_name='')
    return '' if model_name.blank?
    str = ""
    opt = []
    opt << {onclick_func: "addTreeNode();", icon_class: "icon-plus", opt_name: "增加"} if can? :create, model_name.constantize
    opt << {onclick_func: "editTreeNode();", icon_class: "icon-wrench", opt_name: "修改"} if can? :update, model_name.constantize
    opt << {onclick_func: "removeTreeNode();", icon_class: "icon-trash", opt_name: "删除"} if can? :update_destroy, model_name.constantize
    opt << {onclick_func: "freezeTreeNode();", icon_class: "icon-ban", opt_name: "冻结"} if can? :update_freeze, model_name.constantize
    opt << {onclick_func: "recoverTreeNode();", icon_class: "icon-action-undo", opt_name: "恢复"} if can? :update_recover, model_name.constantize

    opt.each do |ha|
      str << %Q{
        <button class='btn' style="font-size:12px;" onclick="#{ha[:onclick_func]}">
          <i class='#{ha[:icon_class]}'></i> #{ha[:opt_name]}
        </button>
      }
    end
    return raw str.html_safe
  end

  # 审核下一步
  def audit_next_step(obj, yijian='通过')
    # ha = { "next" => (obj.get_next_step.is_a?(Hash) ? "确认并转向上级单位审核" : "确认并结束审核流程"), "return" => "退回发起人", "turn" => "转向本单位下一位审核人" }
    ha = obj.audit_next_hash
    str = ""
    step = yijian == "通过" ? (can?(:last_audit, obj) ? "next" : "") : "return"
    str << audit_next_step_label(step, ha[step]) if step.present?
    str << content_tag(:div, audit_next_step_label("turn", ha["turn"]).html_safe, :class=>'inline-group')
    return str.html_safe
  end

  # 审核下一步的label 标签
  def audit_next_step_label(key,value)
    %Q{ <label class="radio"><input type="radio" name="audit_next" value="#{key}"><i class="rounded-x"></i> #{value}</label> }.html_safe
  end

  # 审核理由的弹框
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
    num = 0
    if current_user.to_do_count > 10
      current_user.to_do_list.each_with_index do |obj, index|
        title = %Q|
          #{ link_to obj.to_do_list.name, obj.to_do_list.list_url }
          <span class="label rounded-2x label-red">#{obj.num}</span>
        |
        # desc = "暂时忽略 <i class='fa fa-minus-circle'></i>"
        desc = ""
        str << show_to_do_div(title,desc,index)
        num = index + 1
      end
    else
      current_user.to_do_all.each_with_index do |obj, index|
        title = link_to text_truncate(obj.get_belongs_to_obj.try(:name), 20), obj.to_do_list.get_audit_url(obj.obj_id.to_s), title: obj.get_belongs_to_obj.try(:name)
        desc = "来自 #{obj.to_do_list.name} <i class='fa fa-check-circle'></i>"
        str << show_to_do_div(title,desc,index)
        num = index + 1
      end
    end
    (4-num).times{ |i| str << show_to_do_div('&nbsp;','&nbsp;',-1) }

    return str.html_safe
  end

  # 显示一条待办事项的div
  def show_to_do_div(title,desc,index)
    return %Q|
      <div class="profile-post color-#{index >=0 ? index%7+1 : -1}">
        <span class="profile-post-numb">#{index >=0 ? sprintf("%02d",index+1) : '&nbsp;'}</span>
        <div class="profile-post-in">
            <h3 class="heading-xs">#{title}</h3>
            <p>#{desc}</p>
        </div>
      </div>
    |.html_safe
  end

  # 针对xml类型的字段 ajax增加、删除每一个node
  def ajax_xml_column(obj,column)
    result = show_xml_node_value(obj,column)

    input_str = %Q{
      <i class="icon-append fa fa-info"></i>
      <input id="#{obj.class.to_s.tableize}_#{column}" class="required" type="text" name="#{obj.class.to_s.tableize}[#{column}]" value="">
    }

    submit_click = %Q|ajax_submit_or_remove_xml_column("/kobe/shared/ajax_submit",{id: "#{obj.id}", class_name: "#{obj.class}", column_node: "#{column}"},"##{column}_ajax_submit")|
    result << %Q{
      <div class="row padding-left-10" id="#{column}_ajax_submit">
        <div class="col-md-8 sky-form no-border">#{ content_tag(:label, raw(input_str).html_safe, :class=>'input') }</div>
        <div class="col-md-4"><a class="btn-u btn-u-default" onclick='#{submit_click}'>提交</a></div>
      </div>
    }
    field_str = content_tag(:div, raw(result).html_safe, :class => 'tag-box tag-box-v3 padding-left-5 margin-bottom-5')
    section = content_tag(:section, raw("#{field_str}").html_safe, :class => "col-md-12")
    return content_tag(:div, raw(section).html_safe, :class=>'row')
  end

  # 列表中显示最近操作人
  def show_last_user(obj)
    node = obj.get_last_node_by_logs
    return node.present? ? "#{node.attributes["操作人姓名"].to_str}[#{node.attributes["操作时间"].to_str[0..9]}]".html_safe : ""
  end

  # 显示项目流程图
  def show_step(obj_or_arr, current_index = 0)
    if obj_or_arr.is_a?(Array)
      arr = obj_or_arr
    else
      arr =  obj_or_arr.class.attribute_method?("step_array") ? obj_or_arr.step_array : obj_or_arr.get_obj_step_names
      return "" if arr.blank?
      arr << "完成"
      # 判断当前步骤在数组中的位置 从0开始
      current_index = obj_or_arr.get_current_step_in_array(arr)
    end
    str = %Q{
      <div class="alert alert-info font-size-22">
    }
    arr.each_with_index do |step, index|
      span_cls = (current_index == arr.size-1 || index < current_index) ? "color-green" :  "color-grey"
      i_cls = (index == arr.size - 1) ? "fa-circle-o" : (index < current_index ? "fa-check-circle-o" : "fa-clock-o")
      right_cls = span_cls
      if current_index == index
        span_cls = "color-brown"
        i_cls = "fa-pencil-square-o"
      end
      str << %Q{
        <span class="#{span_cls}"><i class="fa #{i_cls}"></i> #{step}</span>
      }
      unless index == arr.size - 1
        str << %Q{
          <span class="font-size-18 #{right_cls} margin-left-10 margin-right-10"><i class="fa fa-arrow-right"></i></span>
        }
      end
    end
    str << "</div>"
    return str.html_safe
  end

  # 取实例details字段中的某个node的值 用于列表中显示没有column的字段
  def get_details_node_value(obj,name)
    result = ""
    if obj.class.attribute_method?("details") && !obj.attributes["details"].blank?
      doc = Nokogiri::XML(obj["details"])
      tmp = doc.xpath("/root/node[@name='#{name}']").first
      result = tmp.blank? ? "" : tmp["value"]
    end
    return result
  end

  # 面包屑
  def breadcrumbs_tag
    cdt = "(find_in_set(#{current_user.user_type}, user_type) > 0 or find_in_set(#{Dictionary.audit_user_type}, user_type) > 0)"
    menu = Menu.find_by("route_path = ? and #{cdt}", request.fullpath.gsub('.html',''))
    menu = Menu.find_by("route_path = ? and #{cdt}", "/kobe/#{controller_name}/#{action_name}") if menu.blank?
    if menu.present?
      str = "<li>#{link_to '首页', root_path}</li>"
      menu.ancestors.each do |m|
        str << "<li>#{m.route_path.present? ? link_to(m.name, m.route_path) : m.name}</li>"
      end
      str << "<li class='active'>#{menu.name}</li>"
    end

    %Q{
      <div class="breadcrumbs">
        <div class="container"><ul class="breadcrumb">#{str}</ul></div>
      </div>
    }.html_safe
  end

end
