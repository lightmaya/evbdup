# -*- encoding : utf-8 -*-
module ApplicationHelper

  # 格式化日期
  def show_date(d)
    (d.is_a?(Date) || d.is_a?(Time)) ? d.strftime("%Y-%m-%d") : d
  end

  # 格式化时间
  def show_time(t)
    t.is_a?(Time) ? t.strftime("%Y-%m-%d %H:%M:%S") : t
  end

  # 显示序号
  def show_index(index, per = 20)
    params[:page] ||= 1
    (params[:page].to_i - 1) * per + index + 1
  end

  # 将数组转化为a链接,btn是否显示为按钮样式，配合btn_group方法使用
  def arr_to_link(arr,btn=true)
    unless arr.is_a?(Array)
      return arr
    else
      if arr.length < 3 
        opts = btn ? {class: "btn btn-sm btn-default"} : {}
      else
        opts = arr[2]
        if btn
          cls_name = "btn btn-sm btn-default" 
          if opts.has_key?(:class) || opts.has_key?("class")
            cls_name << " #{opts[:class] || opts["class"]}"
          end
          opts[:class] = cls_name
        end
      end
      return link_to(arr[0].html_safe,arr[1],opts)
    end
  end

  # 按钮组,一般应用与操作列表和状态、时间筛选
  def btn_group(arr,dropdown=true)
    return "" if arr.blank?
    unless dropdown || arr.length > 10
      return raw arr.map{|a|arr_to_link(a)}.join(" ").html_safe
    else 
      first = arr_to_link(arr.shift)
      if first.index("<a").nil?
        top = "<button data-toggle='dropdown' class='btn btn-sm btn-default dropdown-toggle' type='button'>#{first} <i class='fa fa-sort-desc'></i></button>"
      else
        top = "#{first}<button data-toggle='dropdown' class='btn btn-sm btn-default dropdown-toggle' type='button'><i class='fa fa-sort-desc'></i></button>"
      end
      # 如果有多个元素就使用按钮组
      unless arr.blank?
        li = arr.map{|c|"<li>#{arr_to_link(c,false)}</li>"}.join("\n")
        str = %Q|
        <div class='btn-group'>
          #{top}
          <ul role='menu' class='dropdown-menu'>
            #{li}
          </ul>
        </div>|
      else
        str = first
      end
      return raw str.html_safe
    end
  end

  # 列表标题栏的筛选过滤器
  def head_filter(name,arr)
    current = params[name] || "all"
    limited = arr.find{|a|a[1].to_s == current }
    arr.delete_if{|a|a[1] == limited[1]}.map!{|a|"<a href='javascript:void(0)' class='#{name}' value='#{a[1]}'>#{a[0]}</a>"}
    arr.unshift(limited[0])
    return btn_group(arr,true)
  end

  # 多个标签的显示,数组中三个标志 title,icon,content
  def show_tabs(arr=[],tag="mytab")
    titles = []
    contents = []
    arr.each_with_index do |a,i|
      icon = a.has_key?(:icon) ? "<i class='fa #{a[:icon]}'></i>" : ""
      if i == 0 
        titles << "<li class='active'><a href='##{tag}-#{i}' data-toggle='tab'><h4>#{icon} #{a[:title]}</h4></a></li>"
        contents << "<div class='tab-pane fade in active' id='#{tag}-#{i}'>#{a[:content]}</div>"
      else
        titles << "<li><a href='##{tag}-#{i}' data-toggle='tab'><h4>#{icon} #{a[:title]}</h4></a></li>"
        contents << "<div class='tab-pane fade in' id='#{tag}-#{i}'>#{a[:content]}</div>"
      end
    end
    return raw %Q|
    <div class="tab-v2">
      <ul class="nav nav-tabs">
        #{titles.join}
      </ul>                
      <div class="tab-content">
        #{contents.join}
      </div>
    </div>|.html_safe
  end

  # 页面提示信息(不是弹框) 
  def show_tips(type,title='',msg='')
    return raw %Q|
      <div class="alert #{get_alert_style(type)} fade in">
        <button class="close" aria-hidden="true" data-dismiss="alert" type="button">×</button>
        <h4>#{title}</h4>
        #{get_tips_msg(msg)}
      </div>|.html_safe
  end

  # 给提示信息加<p>标签 
  def get_tips_msg(msg)
    unless msg.blank?
      if msg.is_a?(Array)
        msg = msg.map{|m|content_tag(:p, m)}.join
      else
        msg = content_tag(:p, msg)
      end
    end
    return msg
  end

  # modal弹框 
  # 按钮要有href="#div_id" data-toggle="modal"
  # 例如<a class="btn btn-sm btn-default" href="#div_id" data-toggle="modal">
  def modal_dialog(div_id='modal_dialog',content='',title='提示')
    raw render(partial: '/shared/dialog/modal_dialog', locals: { div_id: div_id, content: content, title: title }).html_safe
  end

  # 提示信息的样式
  def get_alert_style(type)
    case type
    when "error"
      return 'alert-danger'
    when "tips"
      return 'alert-success'
    when "warning"
      return 'alert-warning'
    else # "info"
      return 'alert-info'
    end
  end

  # 显示步骤,用于用户注册页面
  # def step(arr,step)
  #   len = arr.length
  #   active = Array.new(len){|i| i < step ? " class='active'" : ""}
  #   color = Array.new(len){|i| i < step ? "badge-u" : "badge-light"}
  #   arr.map!.with_index{|a,i|"<li#{active[i]}><a><span class='badge rounded-2x #{color[i]}'>#{i+1}</span> #{a}</a></li>"}
  #   str = %Q|
  #   <div class="step">
  #     <ul class="nav nav-justified">
  #       #{arr.join}
  #     </ul>     
  #   </div>|
  #   return raw str.html_safe
  # end

end
