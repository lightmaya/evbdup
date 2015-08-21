# -*- encoding : utf-8 -*-
class Kobe::SharedController < KobeController
	skip_before_action :verify_authenticity_token
	layout :false
	
  # ajax加载树形结构右侧展示页面的title 用于单位维护、品目参数维护
  def get_ztree_title
  	@obj = eval(params[:model_name]).find_by(id: params[:id])
  end

  # 表单的下拉框 树形结构 只允许menu area category 
  def ztree_json
    if ["Menu", "Area", "Category"].include? params[:json_class]
    	ztree_box_json(params[:json_class].constantize)
    end
  end

  # 转向下一个审核人
  def audit_next_user
    obj = params[:json_class].constantize.find_by(id: params[:id])
    nodes = obj.turn_next_user_json(current_user)
    render :json => nodes.blank? ? "没有相关用户，请先联系管理员授权！" : "[#{nodes.uniq.join(", ")}]"
  end

  # ajax提交xml字段的node
  def ajax_submit
    obj = params[:class_name].constantize.find_by(id: params[:id])
    rs = ""
    if obj.present?
      column = params[:column_node]
      value = params[:column_value]
      # 将提交的node保存到xml字段中
      if value.present?
        if obj[column].present?
          doc = Nokogiri::XML(obj[column])
        else
          doc = Nokogiri::XML::Document.new()
          doc.encoding = "UTF-8"
          doc << "<root>"
        end
        doc.root.add_child("<node>#{value}</node>").first
        obj.update(column.to_sym => doc.to_s)
      end
      # 展示xml字段
      rs = show_xml_node_value(obj,column).html_safe
    end
    render :text => rs
  end

  # ajax删除xml字段的node
  def ajax_remove
    obj = params[:class_name].constantize.find_by(id: params[:id])
    rs = ""
    if obj.present?
      column = params[:column_node]
      index = params[:column_index]
      # 将删除的node保存到xml字段中
      if index.present? && obj[column].present?
        doc = Nokogiri::XML(obj[column])
        doc.css("node")[index.to_i].remove
        obj.update(column.to_sym => doc.to_s)
      end
      # 展示xml字段
      rs = show_xml_node_value(obj,column).html_safe
    end
    render :text => rs
     
  end

  private

end
