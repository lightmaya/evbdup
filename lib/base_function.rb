# -*- encoding : utf-8 -*-
module BaseFunction

  # 获取某实例的字段值
  def get_node_value(obj, node, for_form=false)
    # 父节点特殊处理
    if obj.attributes.include?("ancestry")
    	return obj.parent_id if node["name"] == "parent_id"
    	return obj.parent_name if node["name"] == "父节点名称"
    end
    # 一般情况
    result = ""
    if node.attributes.has_key?("delegate")
      # obj.bid_item.
      result = obj.send(node.attributes["delegate"].to_s).attributes[node["column"]]
    elsif node.attributes.has_key?("column") && obj.class.attribute_method?(node["column"])
    	result = obj.attributes[node["column"]]
    else
    	if obj.class.attribute_method?("details") && !obj.attributes["details"].blank?
        doc = Nokogiri::XML(obj["details"])
        tmp = doc.xpath("/root/node[@name='#{node["name"]}']").first
        result = tmp.blank? ? "" : tmp["value"]
    	end
    end
    result = "%g" % result if result.is_a?(Float)
    return transform_node_value(node,result,for_form)
  end

  # 如果是二维数组的选择类型的，需要转换KEY和VALUE
  def transform_node_value(node,result,for_form=false)
    unless for_form
      if node.attributes.has_key?("data")
        arr = eval(node.attributes["data"].to_str)
        if arr[0].is_a?(Array)
          tmp = arr.find{|d|d[0] == tranform_boolean(result,true)}
          result = tmp[1] unless tmp.blank?
        end
      end
    else
      result = tranform_boolean(result,for_form)
    end
    return result
  end

  # 对布尔型进行转换，在form里要显示数字--1或0，在show时要显示中文--是或否
  def tranform_boolean(s,show_num=true)
    if show_num
      if s == true || s.to_s == "1"
        return 1
      elsif s == false || s.to_s == "0"
        return 0
      else
        return s
      end
    else
      if s == true || s.to_s == "1"
        return "是"
      elsif s == false || s.to_s == "0"
        return "否"
      else
        return s
      end
    end
  end

  # 哈希转成syml格式的字符串，供JS调用
  def hash_to_string(ha)
    if ha.is_a?(Hash)
      arr = []
      ha.each do |key,value|
        arr << "#{key}:#{hash_to_string(value)}"
      end
      return "{#{arr.join(',')}}"
    elsif ha.is_a?(String)
      return "'#{ha}'"
    else
      return ha
    end
  end


  # 显示obj记录的信息 show页面
  def show_obj_info(obj, xml, options = {})
    # td列数
    grid = options[:grid] || 2
    wid = 50/grid
    html = ""
    tbody = ""

    # 标题
    if options[:title].present?
      html << "<h5><i class='fa fa-chevron-circle-down'></i> #{options[:title]}</h5>"
    end

    # 根据xml生成table
    doc = Nokogiri::XML(xml)

    # 先生成输入框--针对没有data_type属性或者data_type属性不包括'大文本'、'富文本'的
    tds = doc.xpath("/root/node[not(@data_type='textarea')][not(@data_type='richtext')][not(@data_type='hidden')][not(@display='skip')]")
    tds.each_slice(grid).with_index do |node, i|
      tbody << "<tr>"
      node.each_with_index{|n, ii|
        tbody << "<td width='#{wid}%'>#{n.attributes["name"]}：</td><td width='#{wid}%'>#{get_node_value(obj,n)}</td>"
        tbody << "<td></td><td></td>" * (grid-ii-1) if (n == node.last) && (ii != grid -1)
      }
      tbody << "</tr>"
    end
    # 再生成文本框和富文本框--针对大文本或者富文本
    doc.xpath("/root/node[contains(@data_type, 'text')]").each_slice(1) do |node|
      node.each{|n|
        tbody << "<tr>"
          tbody << "<td>#{n.attributes["name"]}：</td><td colspan='#{grid*2-1}'>#{get_node_value(obj, n)}</td>"
        tbody << "</tr>"
      }
    end

    html << "<div class='show_obj'><table class='table table-striped table-bordered'><tbody>#{tbody}</tbody></table></div>"
    return html.html_safe
  end

  # 显示总金额
  def show_total_part(total=0, name='总计')
    %Q{
      <div class="show_total">
          <h2 class="text-red">
            <strong>#{name}：￥<span id="form_sum_total">#{total}</span></strong>
          </h2>
      </div>
    }.html_safe
  end

  alias_method :info_html, :show_obj_info

  # 显示评价记录 -- 订单或产品
  def show_estimates(obj)
    something_not_found
  end

  # 显示记录的操作日志
  def show_logs(obj, can_bid = false, doc = nil)
    return "暂无记录" if obj.logs.blank?
    str = []
    doc ||= Nokogiri::XML(obj.logs)
    # 如果是网上竞价或协议议价的 在报价时不显示报价日志
    if can_bid
      doc = Nokogiri::XML(obj.logs)
      # note = doc.search("/root/node[(@操作内容='报价')]") # find all tags with the node_name "note"
      note = doc.search("/root/node[(@操作内容='报价')] | /root/node[(@操作内容='修改报价')]")
      note.remove
    end
    doc.xpath("/root/node").each do |n|
      opt_time = n.attributes["操作时间"].to_s.split(" ")
      # act = n.attributes["操作内容"].to_s[0,2]
      infobar = []
      infobar << "状态:#{obj.status_badge(n.attributes["当前状态"].to_str.to_i)}" if n.attributes.has_key?("当前状态")
      infobar << "姓名:#{n.attributes["操作人姓名"]}"
      infobar << "ID:#{n.attributes["操作人ID"]}"
      infobar << "单位:#{n.attributes["操作人单位"]}"
      infobar << "IP地址:#{n.attributes["IP地址"]}"
      str << %Q|
      <li>
        <time class='cbp_tmtime' datetime=''><span>#{opt_time[1]}</span> <span>#{opt_time[0]}</span></time>
        <i class='cbp_tmicon rounded-x hidden-xs'></i>
        <div class='cbp_tmlabel'>
          <h4><i class="fa fa-chevron-circle-right"></i> #{obj.class.icon_action(n.attributes["操作内容"].to_str,false)}</h4>
          <div class="no-display margin-bottom-10">#{n.attributes["备注"]}</div>
          <p>#{infobar.join("&nbsp;&nbsp;")}</p>
        </div>
      </li>|
    end
    return "<ul class='timeline-v2'>#{str.reverse.join}</ul>"
  end

  # 显示图片 用于上传产品图片、注册单位上传证件 点小图弹出大图
  def show_picture(small_pic_url, large_pic_url, title = "", rel = 'pics')
    %Q{
      <div class="thumbnails thumbnail-style thumbnail-kenburn">
        <div class="thumbnail-img">
          <div class="overflow-hidden">
            <a href="#{large_pic_url}" title="#{title}" rel="#{rel}" class="fancybox">
              <span><img alt="" src="#{small_pic_url}" class="img-responsive"></span>
            </a>
          </div>
        </div>
        <div class="caption">
          <p class="word_break">#{title}</p>
        </div>
      </div>
      }.html_safe
  end

  # 显示附件
  def show_uploads(obj, options = {})
    options[:is_picture] ||= false
    options[:grid] ||= 4
    result = ""
    # 标题
    if options[:title].present?
      if options[:title] == true
        options[:title] = "附件信息"
      end
      result << "<h5><i class='fa fa-chevron-circle-#{obj.uploads.present? ? "down" : "right"}'></i> #{options[:title]}</h5>"
    end
    return (result + "<div class='hide'>#{something_not_found(options[:icon_not_found])}</div>").html_safe if obj.uploads.blank?
    # 图片类型
    if options[:is_picture]
      tmp = obj.uploads.map do |file|
        %Q|<div class="col-md-#{12/options[:grid]}">
          #{show_picture(file.upload.url(:md), file.upload.url(:lg), file.upload_file_name, obj.class.to_s.tableize)}
        </div>|.html_safe
      end
    # 非图片类型
    else
      tmp = obj.uploads.map do |file|
        %Q|<div class="col-md-#{12/options[:grid]}">
          <div class="servive-block servive-block-default">
            <a href="#{file.upload.url(:original)}" title="#{file.upload_file_name}" target="_blank">
              <img alt="" src="#{file.to_jq_upload["thumbnail_url"]}">
              <p class="word_break">#{file.upload_file_name}<br>[#{number_to_human_size(file.upload_file_size)}]</p>
            </a>
          </div>
        </div>|.html_safe
      end
    end
    tmp.each_slice(options[:grid]) do |t|
      result << "<div class='row'>#{t.join}</div>"
    end
    return result.html_safe
  end

  alias_method :uploads_html, :show_uploads

  # 生成随机数
  def create_random_chars(len)
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    tmp = ""
    1.upto(len) {|i| tmp << chars[rand(chars.size-1)]}
    return tmp
  end

  def something_not_found(icon=false)
    return "<div class='padding-left-20'>抱歉，没有找到相关信息。</div>" if icon
    %Q|
      <div class="content-boxes-v2 space-lg-hor content-sm">
        <h2 class="heading-sm">
          <i class="icon-custom icon-sm icon-bg-red fa fa-lightbulb-o"></i>
          <span>抱歉，没有找到相关信息。</span>
        </h2>
      </div>
    |.html_safe
    # "<div class='alert alert-warning fade in'><h4><i class='fa fa-frown-o font_24px'></i> 抱歉，没有找到相关信息。</h4></div>".html_safe
  end

  #  截取字符串固定长度，支持中英文混合，length 为中文的长度，一个英文相当于0.5个中文长度
  def text_truncate(text, length = 30, truncate_string = "...")
    if text
      l=0
      char_array=text.unpack("U*")
      char_array.each_with_index do |c,i|
        l = l+ (c<127 ? 0.5 : 1)
        if l>=length
          return char_array[0..i].pack("U*")+(i ? truncate_string : "")
        end
      end
      return text
    else
      return ""
    end
  end

  # 显示xml类型的node的值
  def show_xml_node_value(obj,column)
    result = ""
    doc = Nokogiri::XML(obj[column])
    doc.css("node").each_with_index do |n,i|
      remove_click = %Q|ajax_submit_or_remove_xml_column("/kobe/shared/ajax_remove",{id: "#{obj.id}", class_name: "#{obj.class}", column_node: "#{column}", column_index: "#{i}"},"##{column}_ajax_submit")|
      result << %Q{
        <div class="bg-light bg-color-white rounded margin-bottom-10 margin-left-10">
          <button class="close margin-left-10" data-dismiss="alert" type="button" onclick='#{remove_click}'>×</button>
          #{n.to_str}
        </div>
      }
    end
    result << "<hr/>" if result.present?
    return result
  end

  # show页面显示预算审批单 需要的hash
  def get_budget_hash(budget, dep_id)
    if budget.present? && current_user.real_department.is_ancestors?(dep_id)
      budget_contents = show_obj_info(budget, Budget.xml)
      budget_contents << show_uploads(budget)
      { title: "预算审批单", icon: "fa-paperclip", content: budget_contents }
    end
  end

end
