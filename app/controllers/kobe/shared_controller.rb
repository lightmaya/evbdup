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

  # 指定入围供应商项目
  def item_ztree_json
    name = params[:ajax_key]
    if name.present?
      nodes = Item.usable.where(["name like ? ", "%#{name}%"]).order('id desc')
    else
      nodes = Item.usable.order('id desc')
    end
    json = nodes.map{|n|%Q|{"id":#{n.id}, "pId": 0, "name":"#{n.name}"}|}
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
    yw_cdt = params[:yw_type].present? ? "yw_type % #{params[:yw_type].to_i} = 0" : ""
    name = params[:ajax_key]
    status = Category.effective_status
    if name.blank?
      nodes = yw_cdt.present? ? Category.where(status: status).where(yw_cdt) : Category.where(status: status)
    else
      cdt = "and a.status in (#{status.join(', ')}) and b.status in (#{status.join(', ')}) "
      cdt << " and a.#{yw_cdt} and b.#{yw_cdt}" if yw_cdt.present?
      sql = ztree_box_sql(Category, cdt)
      # sql = "SELECT DISTINCT a.id,a.name,a.ancestry FROM #{Category.to_s.tableize} a INNER JOIN  #{Category.to_s.tableize} b ON (FIND_IN_SET(a.id,REPLACE(b.ancestry,'/',',')) > 0 OR a.id=b.id OR (LOCATE(CONCAT(b.ancestry,'/',b.id),a.ancestry)>0)) WHERE b.name LIKE ? #{cdt} ORDER BY a.ancestry"
      nodes = Category.find_by_sql([sql,"%#{name}%"])
    end
    render :json => Category.get_json(nodes)
  end

  # 状态是正常的品目
  def department_ztree_json
    name = params[:ajax_key]
    status = Department.effective_status
    dep_p = Department.purchaser
    if name.blank?
      nodes = dep_p.descendants.where(status: status, dep_type: false)
    else
      cdt = "and a.status in (#{status.join(', ')}) and b.status in (#{status.join(', ')}) and a.dep_type is false and b.dep_type is false and (b.ancestry like '#{dep_p.id}/%' or  b.ancestry = #{dep_p.id})"
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
  # def get_budgets_json
  #   json = current_user.valid_budgets.map{|n|%Q|{"id":#{n.id}, "pId": 0, "name":"#{n.name} [预算金额: <span class='red'>#{n.total}</span>]"}|}
  #   render :json => json.blank? ? '' : "[#{json.join(", ")}]"
  # end

  # 订单填写预算的表单
  def get_budget_form
    title = params[:id].present? ? "<i class='fa fa-pencil-square-o'></i> 修改预算" : "<i class='fa fa-pencil-square-o'></i> 填写预算"
    @budget = params[:id].present? ? Budget.find_by(id: params[:id]) : Budget.new
    @myform = SingleForm.new(nil, @budget, { form_id: "budget_form", button: false, upload_files: true, min_number_of_files: 1, title: false })
  end

  # 在budgets表保存预算 返回 id 和 total
  def save_budget
    if params[:id].present?
      budget = Budget.find_by id: params[:id]
      budget.update(total: params[:total], summary: params[:summary])
    else
      budget = Budget.create(total: params[:total], summary: params[:summary], name: "#{current_user.real_department.name} #{Time.now.to_date} 预算", department_id: current_user.department.id, dep_code: current_user.real_dep_code)
    end
    upload_ids = params[:uids].split(",")
    BudgetUpload.where(id: upload_ids).update_all(master_id: budget.try(:id))
    render json: { id: budget.id, total: budget.total.to_f }
  end

  # 生成项目名称和入围单位名称的树形json
  def item_dep_json
    name = params[:ajax_key]
    json = []
    Item.usable.order('id desc').each do |n|
      deps = name.present? ? n.item_departments.where(["name like ? ", "%#{name}%"]) : n.item_departments
      json << %Q|{"id":#{n.id}, "pId": 0, "name":"#{n.short_name}"}| if deps.present?
      deps.each { |d| json << %Q|{"id":#{d.department_id.present? ? d.department_id : -1}, "pId": #{d.item_id}, "name":"#{d.name}"}| }
    end
    render :json => "[#{json.join(", ")}]"
  end

end
