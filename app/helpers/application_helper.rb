# -*- encoding : utf-8 -*-
module ApplicationHelper
  # 网页title
  def title(page_title)
    content_for :title, page_title.to_s
  end

  # 加载css: <%= stylesheets 'my1','my2' %>
  def stylesheets(*args)
    stylesheet_link_tag(*args)
  end

  # 加载js: <%= javascripts 'my1','my2' %>
  def javascripts(*args)
    javascript_include_tag(*args)
  end

  # 必须项，红星
  def require_span
    "<span class='red'>* </span>".html_safe
  end

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
  def btn_group(arr, dropdown=true)
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

  # 项目名称+多标签显示 用于show和audit
  def show_tabs_with_name(name, arr, tag = 'mytab')
    str = show_tips("warning", "<i class='fa fa-paper-plane font_24px'></i> #{name}")
    str << show_tabs(arr, tag)
    str.html_safe
  end

  # 多个标签的显示,数组中三个标志 title,icon,content
  def show_tabs(arr=[],tag="mytab")
    titles = []
    contents = []
    arr.compact.each_with_index do |a,i|
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
        <h4>#{title}</h4>
        #{get_tips_msg(msg)}
      </div>|.html_safe
  end

  # 给提示信息加<p>标签
  def get_tips_msg(msg)
    unless msg.blank?
      if msg.is_a?(Array)
        msg = msg.map{|m|content_tag(:p, m.html_safe)}.join
      else
        msg = content_tag(:p, msg.html_safe)
      end
    end
    return msg
  end

  def log_rs(doc, node = 'node')
    begin
      Nokogiri::XML(doc).xpath("//#{node}")
    rescue Exception => e
      []
    end
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

  # # 网页title
  # def title(page_title)
  #   content_for :title, page_title.to_s
  # end

  # # 加载css: <%= stylesheets 'my1','my2' %>
  # def stylesheets(*args)
  #   stylesheet_link_tag(*args)
  # end

  # # 加载js: <%= javascripts 'my1','my2' %>
  # def javascripts(*args)
  #   javascript_include_tag(*args)
  # end

  def link_to_blank(*args, &block)
    if block_given?
      options      = args.first || {}
      html_options = args.second || {}
      link_to_blank(capture(&block), options, html_options)
    else
      name         = args[0]
      options      = args[1] || {}
      html_options = args[2] || {}

      # override
      html_options.reverse_merge! target: '_blank'

      link_to(name, options, html_options)
    end
  end

  # 加载富文本框插件UMeditor
  def include_umeditor
    javascripts("/plugins/umeditor1_2_2/umeditor.config.js",
      "/plugins/umeditor1_2_2/umeditor.min.js",
      "/plugins/umeditor1_2_2/lang/zh-cn/zh-cn.js"
      ) +
    stylesheets("/plugins/umeditor1_2_2/themes/default/css/umeditor.css")
  end

  # 加载富文本框插件Ueditor
  def include_ueditor
    javascripts("/plugins/ueditor1_4_3/ueditor.config.js",
      "/plugins/ueditor1_4_3/ueditor.all.js",
      "/plugins/ueditor1_4_3/lang/zh-cn/zh-cn.js",
      "/plugins/ueditor1_4_3/ueditor.parse.js"
      )
  end

  def link_to_void(*args, &block)
    link_to(*args.insert((block_given? ? 0 : 1), "javascript:void(0)"), &block)
  end

  def dict_value(str, key, index = 1)
    values = Dictionary.send(key)
    return "" if values.blank?
    if values.is_a?(Array)
      tmp = values.find{|ary| ary.first == str}
      tmp.is_a?(Array) ? tmp[index] : ""
    elsif values.is_a?(Hash)
      values[str]
    else
      ""
    end
  end

   #  显示金额 允许带单位显示 pre 前缀 ￥
  def money(number, pre="", precision=2)
    return 0 if number.to_f == 0
    return pre << number_to_currency(number, {:unit => "¥", :delimiter => ",", :precision => precision, format: "%u%n"})
  end

  #大写
  def total_money_cn(n)
    cNum = ["零","壹","贰","叁","肆","伍","陆","柒","捌","玖","-","-","万","仟","佰","拾","亿","仟","佰","拾","万","仟","佰","拾","元","角","分"]
    cCha = [['零元','零拾','零佰','零仟','零万','零亿','亿万','零零零','零零','零万','零亿','亿万','零元'],[ '元','零','零','零','万','亿','亿','零','零','万','亿','亿','元']]

    i = 0
    sNum = ""
    sTemp = ""
    result = ""
    tmp = ("%.0f" % (n.abs.to_f * 100)).to_i
    return '零' if tmp == 0
    raise '整数部分加二位小数长度不能大于15' if tmp.to_s.size > 15
    sNum = tmp.to_s.rjust(15, ' ')

    for i in 0..14
      stemp = sNum.slice(i, 1)
      if stemp == ' '
        next
      else
        result += cNum[stemp.to_i] + cNum[i + 12];
      end
    end

    for m in 0..12
      result.gsub!(cCha[0][m], cCha[1][m])
    end

    if result.index('零分').nil? # 没有分时, 零角改成零
      result.gsub!('零角','零')
    else
      if result.index('零角').nil? # 有没有分有角时, 后面加"整"
        result += '整'
      else
        result.gsub!('零角', '整')
      end
    end

    result.gsub!('零分', '')
    "#{n < 0 ? "负" : ""}#{result}"
  end

  def label_tag(text, style = 'info', options = {})
    style = 'info' if style.blank?
    options[:title] ||= text
    "<span title='#{options[:title]}' class='label label-#{style}'>#{text}</span>".html_safe
  end

  def link_to_channel(h = {}, options = {})
    return "" if h[:title].blank?
    combos = params[:combo].split("_")
    combos[Product::QS.index(h[:q])] = h[:id]
    combos.each_with_index{|o, i| combos[i] = 0 if o.nil?}
    title = h[:title]
    title += '<span style="color: red;"> X</span>' if options[:del]
    link_to title.html_safe, channel_path(combos.join("_"))
  end

  # 给某字符串加icon标签 icon_location 表示icon的位置是在字符串的左边还是右边
  def get_name_with_icon(name, icon, icon_location = 'left')
    return name if icon.blank?
    icon_location == 'left' ? "<i class='fa #{icon}'></i> #{name}" : "#{name} <i class='fa #{icon}'></i>"
  end

  def cart_tag
    %Q{
      <a href="#{cart_path}">
        <i class="fa fa-shopping-cart"></i> 购物车
        <span class="badge badge-red rounded-x">#{@cart.items.size}</span>
      </a>
    }.html_safe
  end

  # 供应商分级标签 classify指数据库中存的数值 对应Dictionary.dep_classify数组第一位
  def dep_classify_tag(classify)
    "<span title='#{dict_value(classify, "dep_classify")}' class='btn-u btn-u-sm btn-u-#{dict_value(classify, "dep_classify", 2)}'>#{dict_value(classify, "dep_classify")}</span>".html_safe
  end

  # 供应商分级 只有字体颜色 没有标签背景色
  def dep_classify_span(classify)
    "<span class='color-#{dict_value(classify, "dep_classify", 2)}'>#{dict_value(classify, "dep_classify")}</span>".html_safe
  end

end
