# -*- encoding : utf-8 -*-
class Kobe::SharedController < KobeController
	skip_before_action :verify_authenticity_token
	layout :false
  skip_load_and_authorize_resource 
	
  # ajax加载树形结构右侧展示页面的title 用于单位维护、品目参数维护
  def get_ztree_title
  	@obj = eval(params[:model_name]).find_by(id: params[:id])
    if @obj.blank?
      render :text => ''
    end
  end

  # 表单的下拉框 树形结构 只允许menu area category 
  def ztree_json
    if ["Menu", "Area", "ArticleCatalog", "DailyCategory"].include? params[:json_class]
    	ztree_box_json(params[:json_class].constantize)
    end
  end

  # 用户权限 按user.user_type授权 
  # 单位状态不是正常的 只有menu.is_auto=true & user.user_type = current_user.user_type的权限
  def user_ztree_json
    name = params[:ajax_key]
    user = User.find_by(id: params[:id])
    nodes = user.get_auto_menus

    if name.present?
      ids = nodes.map(&:id)
      cdt = "and a.status != 404 and b.status != 404 and a.id in (#{ids}) and b.id in (#{ids})"
      sql = ztree_box_sql(Menu, cdt)
      nodes = Menu.find_by_sql([sql,"%#{name}%"])
    end
    render :json => Menu.get_json(nodes)
  end

  def item_ztree_json
    json = Item.all.map{|n|%Q|{"id":#{n.id}, "pId": 0, "name":"#{n.name}"}|}
    render :json => "[#{json.join(", ")}]" 
  end

  # 只显示省级地区
  def province_area_ztree_json
    name = params[:ajax_key]
    if name.blank?
      nodes = Area.to_depth(2)
    else
      cdt = "and a.ancestry_depth <= 2 and b.ancestry_depth <= 2"
      sql = ztree_box_sql(Area, cdt)
      nodes = Area.find_by_sql([sql,"%#{name}%"])
    end
    render :json => Area.get_json(nodes)
  end

  # 状态是正常的品目
  def category_ztree_json
    name = params[:ajax_key]
    if name.blank?
      nodes = Category.where(status: 0)
    else
      cdt = "and a.status = 0 and b.status = 0" 
      sql = ztree_box_sql(Category, cdt)
      # sql = "SELECT DISTINCT a.id,a.name,a.ancestry FROM #{Category.to_s.tableize} a INNER JOIN  #{Category.to_s.tableize} b ON (FIND_IN_SET(a.id,REPLACE(b.ancestry,'/',',')) > 0 OR a.id=b.id OR (LOCATE(CONCAT(b.ancestry,'/',b.id),a.ancestry)>0)) WHERE b.name LIKE ? #{cdt} ORDER BY a.ancestry"
      nodes = Category.find_by_sql([sql,"%#{name}%"])
    end
    render :json => Category.get_json(nodes)
  end

    # 状态是正常的品目
  def department_ztree_json
    name = params[:ajax_key]
    dep_p = Department.purchaser
    if name.blank?
      nodes = dep_p.descendants.where(status: 1, dep_type: false) 
    else
      cdt = "and a.status = 1 and b.status = 1 and a.dep_type is false and b.dep_type is false and (b.ancestry like '#{dep_p.id}/%' or  b.ancestry = #{dep_p.id})" 
      sql = ztree_box_sql(Department, cdt)
      # sql = "SELECT DISTINCT a.id,a.name,a.ancestry FROM #{Category.to_s.tableize} a INNER JOIN  #{Category.to_s.tableize} b ON (FIND_IN_SET(a.id,REPLACE(b.ancestry,'/',',')) > 0 OR a.id=b.id OR (LOCATE(CONCAT(b.ancestry,'/',b.id),a.ancestry)>0)) WHERE b.name LIKE ? #{cdt} ORDER BY a.ancestry"
      nodes = Department.find_by_sql([sql,"%#{name}%"])
    end
    render :json => Department.get_json(nodes)
  end


  # 转向下一个审核人
  def audit_next_user
    obj = params[:json_class].constantize.find_by(id: params[:id])
    nodes = obj.turn_next_user_json(current_user)
    render :json => nodes.blank? ? "" : "[#{nodes.uniq.join(", ")}]"
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

  # 根据项目选择要新增的品目
  def get_item_category
    if params[:model_name].blank? || params[:item_id].blank? || params[:url].blank?
      @categories = []
    else
      @item = eval(params[:model_name]).find_by(id: params[:item_id])
      @categories = @item.class.attribute_method?("categories") ? @item.categories : []
      @url = params[:url]
    end
  end

  # 当前用户的可用的预算审批单的json
  def get_budgets_json
    json = current_user.valid_budgets.map{|n|%Q|{"id":#{n.id}, "pId": 0, "name":"#{n.name} [预算金额: <span class='red'>#{n.budget}</span>]"}|}
    render :json => json.blank? ? '' : "[#{json.join(", ")}]" 
  end

  private

end
