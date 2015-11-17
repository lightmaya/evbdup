# -*- encoding : utf-8 -*-
module AdvancedSearchHelper

  # 目前只支持单选的高级搜索
  def get_search_input(model_name, xml, f)
    input_str = ""
    doc = Nokogiri::XML(xml)
    doc.xpath("/root/node").each do |node|
      name = node.attributes["name"].blank? ? "" : node.attributes["name"].to_s
      tmp = %Q{<label class="col-lg-3 control-label" for="inputEmail1">#{name}</label>}
      tmp << (node.attributes["data_type"].to_s == "select" ? get_search_select(node) : get_search_field(node, f))
      input_str << content_tag(:div, raw(tmp).html_safe, :class=>'form-group')
    end
    return input_str
  end

  # 根据node生成可输入的input 或日期类型的input 或者下拉tree_radio类型
  def get_search_field(node, f)
    name = node.attributes["name"].blank? ? "" : node.attributes["name"].to_s
    column = node.attributes["column"].blank? ? "" : node.attributes["column"].to_s
    field_ha = {}
    field_ha[:class] = "form-control"
    field_ha[:class] << " #{node.attributes["class"].to_s}" if node.attributes["class"].present?
    field_ha[:placeholder] = node.attributes["placeholder"].present? ? node.attributes["placeholder"].to_s : "请输入#{name}..."
    field_ha[:json_url] = node.attributes["json_url"].to_s if node.attributes["json_url"].present?
    return content_tag(:div, raw(f.search_field(column.to_sym, field_ha).to_str).html_safe, :class=>'col-lg-9')
  end

  def get_search_select(node)
    column = node.attributes["column"].blank? ? "" : node.attributes["column"].to_s
    data_str = "<option value=''>请选择...</option>\n"
    data = eval(node.attributes["data"].value)
    if data.is_a?(Hash)
      data.each { |k, v| data_str << "<option value='#{k}'>#{v}</option>\n" }
    else
      data.each { |d| data_str << (d.is_a?(Array) ? "<option value='#{d[0]}'>#{d[1]}</option>\n" : "<option value='#{d}'>#{d}</option>\n") }
    end

    str = %Q{
      <select id="q_#{column}"  name="q[#{column}]"  class="form-control" type="search">
        #{data_str}
      </select>
      <i></i>
    }

    return content_tag(:div, raw(str).html_safe, :class=>'col-lg-9 select')
  end

  # 生成高级搜索的form
  def get_advanced_search_form(search_url, model_name, xml)
    str = search_form_for(@q, url: search_url, html: { method: :get, class: 'sky-form no-border form-horizontal' }) { |f| get_search_content(model_name, xml, f) }
    content_tag(:div, raw(str).html_safe, class: 'tag-box tag-box-v6 col-sm-offset-2 col-sm-8')
  end

  def get_search_content(model_name, xml, f)
    str = get_search_input(model_name, xml, f)
    str << content_tag(:div, raw('<button class="btn btn-success btn-sm" type="submit">搜索</button>').html_safe, class: 'form-group heading')
    return str.html_safe
  end


end