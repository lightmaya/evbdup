# -*- encoding : utf-8 -*-
namespace :data do
  desc '导入协议供货产品'
  task :products => :environment do
    p "#{begin_time = Time.now} in products....."

    Dragon.table_name = "zcl_product"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    audit_total = 0
    Dragon.find_each do |zcl_product|
      i += 1
      pr = Product.find_or_initialize_by(id: zcl_product.id)
      pr.category_id = zcl_product.zcl_category_id
      pr.category_code = pr.category.present? ? pr.category.ancestry : 0
      pr.item_id = zcl_product.item_id
      pr.brand = zcl_product.brand
      pr.model = zcl_product.name
      pr.version = zcl_product.xinghao
      pr.unit = zcl_product.unit
      pr.market_price = zcl_product.market_price
      pr.bid_price = zcl_product.bid_price
      pr.summary = get_value_in_xml(zcl_product.detail, "基本描述")
      pr.user_id = zcl_product.user_id
      new_dep = Department.find_by(old_id: zcl_product.user_dep, old_table: "dep_supplier")
      pr.department_id = new_dep.id if new_dep.present?
      # "未提交",0,"orange",10],
      # ["正常",1,"u",100],
      # ["等待审核",2,"blue",50],
      # ["审核拒绝",3,"red",0],
      # ["冻结",4,"yellow",20],
      # ["已删除",404,"light",0]
      pr.status = case zcl_product.status
      when "未提交"
        0
      when "有效", "新增审核通过"
        65
      when "新增等待审核"
        8
      when "新增审核拒绝"
        7
      when "已删除"
        404
      when "已撤销", "撤销审核通过"
        26
      end
      pr.details = zcl_product.detail.to_s.gsub("param", "node")
      pr.logs = zcl_product.logs.to_s.gsub("param", "node").gsub("&lt;table&gt;", "&lt;table class=&quot;table table-bordered&quot;&gt;")
      pr.logs = replace_status_in_logs(pr.logs, [["未提交", 0], ["有效", 65], ["新增审核通过", 65], ["新增等待审核", 8], ["新增审核拒绝", 7], ["已删除", 404], ["已撤销", 26], ["撤销审核通过", 26], ["撤销审核拒绝", 26], ["撤销等待审核", 26]])
      pr.created_at = zcl_product.created_at
      pr.updated_at = zcl_product.updated_at
      if pr.save
        # 如果状态是等待审核 插入待办事项
        if pr.status == 8
          audit_total += 1
          pr.create_task_queue(get_user_id_in_audit_log(zcl_product))
        end
        succ += 1
        p "succ: #{succ}/#{total} zcl_product_id: #{zcl_product.id}"
      else
        log_p "[error]zcl_product_id: #{zcl_product.id} | #{pr.errors.full_messages}" ,"data_products.log"
      end
      # break if i > max
    end

    tqs = TaskQueue.where(class_name: "Product")
    p ".products_audit succ: #{tqs.size}/#{audit_total} [user_id, dep_id]: #{tqs.group(:user_id, :dep_id).count(:id)}"

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入单位'
  task :departments => :environment do
    p "#{begin_time = Time.now} in departments....."

    if Department.first.blank?
      [["采购单位", 2], ["供应商", 3], ["监管机构", 1], ["评审专家", 4]].each do |option|
        Department.find_or_create_by(:name => option[0], :status => 65, id: option[1])
      end
    end

    old_table_name = "dep_purchaser"
    Dragon.table_name = old_table_name
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      i += 1
      d = Department.find_or_initialize_by(old_id: old.id, old_table: old_table_name)
      next if d.id.present?
      d.parent_id = 2 if old.id == 144
      d.name = old.id == 144 ? "中国储备粮管理总公司" : (old.name == "中国储备粮管理总公司" ? "总公司机关" : old.name)
      d.is_secret = old.secret == "是"
      d.dep_type = old.name == "中国储备粮管理总公司" ? 1 : 0
      d.old_name = old.old_name
      d.short_name = old.short_name
      d.status = case old.status
      when "正常"
        65
      when "已删除"
        404
      end
      d.org_code = old.org_code
      d.legal_name = old.legal_person_name
      d.legal_number = old.legal_person_ssn
      d.address = old.detail_address
      d.post_code = old.postalcode
      d.website = old.web_site
      d.tel = old.telephone
      d.fax = old.fax
      d.summary = old.description
      d.area_id = old.city_id
      d.sort = old.name == "中国储备粮管理总公司" ? 0 : old.sort
      d.details = old.detail.to_s.gsub("param", "node")
      d.logs = old.logs.to_s.gsub("param", "node").gsub("&lt;table&gt;", "&lt;table class=&quot;table table-bordered&quot;&gt;")
      d.logs = replace_status_in_logs(d.logs, [["正常", 65], ["有效", 65], ["已删除", 404]])
      d.created_at = old.created_at
      d.updated_at = old.updated_at
      if d.save
        succ += 1
        p ".departments succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{d.errors.full_messages}" ,"departments.log"
      end
    end

    # 导入层级关系
    Dragon.order("code asc").each do |old|
      n = Department.find_or_initialize_by(old_id: old.id, old_table: old_table_name)
      next if old.id == 144 || n.ancestry.present?
      n.parent_id = Department.find_by(old_id: old.parent_id, old_table: old_table_name)
      if n.save
        p ".departments ancestry: #{n.ancestry} succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"departments.log"
      end
    end

    # 导入供应商单位
    old_table_name = "dep_supplier"
    Dragon.table_name = old_table_name
    max = 1000 ; succ = i = 0
    total = Dragon.count
    audit_total = 0
    Dragon.find_each do |old|
      i += 1
      d = Department.find_or_initialize_by(old_id: old.id, old_table: old_table_name)
      next if d.id.present?
      d.parent_id = 3
      d.name = old.name
      d.is_secret = false
      d.old_name = old.old_name
      d.short_name = old.short_name
      d.status = case old.status

      #   [
      #   ["未提交",0,"orange",10],
      #   ["正常",1,"u",100],
      #   ["等待审核",2,"blue",50],
      #   ["审核拒绝",3,"red",0],
      #   ["冻结",4,"yellow",20],
      #   ["已删除",404,"light",0]
      # ]
      when "正常"
        65
      when "已删除"
        404
      when "审核不通过"
        7
      when "注册未完成"
        0
      when "已冻结"
        12
      when "等待审核"
        8
      else
        404
      end
      d.org_code = old.org_code
      d.legal_name = old.legal_person_name
      d.legal_number = old.legal_person_ssn
      d.address = old.detail_address
      d.post_code = old.postalcode
      d.website = old.web_site
      d.tel = old.telephone
      d.fax = old.fax
      d.summary = old.short_desc
      d.area_id = old.city_id
      d.sort = old.sort
      d.details = old.detail.to_s.gsub("param", "node")
      d.logs = old.logs.to_s.gsub("param", "node").gsub("&lt;table&gt;", "&lt;table class=&quot;table table-bordered&quot;&gt;")
      d.logs = replace_status_in_logs(d.logs, [["正常", 65], ["有效", 65], ["已删除", 404], ["审核不通过", 7], ["注册未完成", 0], ["已冻结", 12], ["等待审核", 8]])
      d.created_at = old.created_at
      d.updated_at = old.updated_at

      # d.comment_total = old.comment_total
      d.capital = old.registered_funds
      d.license = old.license_code
      d.tax = old.national_tax_num
      d.bank = old.bank_name
      d.bank_code = old.bank_code
      d.bank_account = old.bank_account
      d.turnover = old.turnover_of_last_year
      d.employee = old.employment_size
      d.is_blacklist = old.blacklist

      if d.save
        # 如果状态是等待审核 插入待办事项
        if d.status == 8
          audit_total += 1
          d.create_task_queue(get_user_id_in_audit_log(old))
        end
        succ += 1
        p ".departments succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{d.errors.full_messages}" ,"departments.log"
      end
    end

    tqs = TaskQueue.where(class_name: "Department")
    p ".departments_audit succ: #{tqs.size}/#{audit_total} [user_id, dep_id]: #{tqs.group(:user_id, :dep_id).count(:id)}"

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入协议供货项目'
  task :items => :environment do
    p "#{begin_time = Time.now} in items....."

    Dragon.table_name = "zcl_item"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      i += 1
      n = Item.find_or_initialize_by(id: old.id)
      n.name = old.item_name
      n.begin_time = old.begin_time
      n.end_time = old.end_time
      n.categoryids = old.category_id

      n.status = case old.status
      when "停止申请"
        54
      when "已停止"
        54
      when "已删除"
        404
      when "有效"
        65
      else
        404
      end

      n.user_id = old.user_id
      n.details = old.detail.to_s.gsub("param", "node")
      n.logs = old.logs.to_s.gsub("param", "node").gsub("&lt;table&gt;", "&lt;table class=&quot;table table-bordered&quot;&gt;")
      n.logs = replace_status_in_logs(n.logs, [["有效", 65], ["已删除", 404], ["已停止", 54], ["停止申请", 54]])
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.save
        succ += 1
        p ".items succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"data_items.log"
      end

    end

    Dragon.table_name = "zcl_item_factory"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      next unless old.status == "申请审核通过"
      n = ItemDepartment.find_or_initialize_by(id: old.id)
      n.item_id = old.zcl_item_id
      new_dep = Department.find_by(old_id: old.user_dep, old_table: "dep_supplier")
      next if new_dep.blank?
      n.department_id = new_dep.id
      n.name = new_dep.name
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.save
        succ += 1
        p ".item_departments succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"item_departments.log"
      end

    end

    Item.fix_dep_names

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '根据截止时间更新协议供货项目'
  task :update_items => :environment do
    p "#{begin_time = Time.now} in items....."

    succ = 0
    items = Item.where(status: Item.effective_status)
    items.each do |i|
      next unless i.is_end?
      # ["已过期", "54"]: ["dark", 100]
      i.change_status_and_write_logs("已过期", save_logs(i.logs, "过期", 54, "系统自动更新过期的项目"))
      succ += 1
      p ".item_departments succ: #{succ}/#{items.size} old: #{i.id}"
    end

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end


  desc '导入代理商'
  task :agents => :environment do
    p "#{begin_time = Time.now} in agents....."

    Dragon.table_name = "zcl_agents"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      n = Agent.find_or_initialize_by(id: old.id)

      new_dep = Department.find_by(old_id: old.user_dep, old_table: "dep_supplier")
      next if new_dep.blank?
      n.department_id = new_dep.id
      n.name = old.agent_name
      if old.user_dep == old.agent_id
        n.agent_id = n.department_id
      else
        a_dep = Department.find_by(old_id: old.agent_id, old_table: "dep_supplier")
        next if a_dep.blank?
        n.agent_id = a_dep.id
      end
      n.area_id = old.city
      n.category_id = old.category_id
      ca_ids = old.category_id.split(",")
      n.department.items.each do |item|
        i_ca_ids = item.categoryids.split(",")
        n.item_id = item.id if (ca_ids & i_ca_ids).present?
      end
      # ["正常",0,"u",100],
      # ["已删除",404,"light",0]
      n.status = case old.status
      when "自动生效", "新增审核通过"
        65
      when "已暂停", "新增审核拒绝", "未提交", "新增等待审核"
        404
      else
        404
      end

      n.user_id = old.user_id
      n.logs = old.logs.to_s.gsub("param", "node").gsub("&lt;table&gt;", "&lt;table class=&quot;table table-bordered&quot;&gt;")
      n.logs = replace_status_in_logs(n.logs, [["自动生效", 65], ["有效", 65], ["新增审核通过", 65], ["已暂停", 404], ["新增审核拒绝", 404], ["未提交", 404], ["新增等待审核", 404]])
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.save
        succ += 1
        p "agents succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"agents.log"
      end
    end
    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入总协调人'
  task :coordinators => :environment do
    p "#{begin_time = Time.now} in coordinators....."

    Dragon.table_name = "zcl_zxtr"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      n = Coordinator.find_or_initialize_by(id: old.id)
      next if old.user_type == 2
      dep = Department.find_by(old_id: old.user_dep, old_table: "dep_supplier")
      next if dep.blank?
      n.department_id = dep.id
      n.name = get_value_in_xml(old.detail, "总协调人")
      n.tel = get_value_in_xml(old.detail, "联系电话")
      n.mobile = get_value_in_xml(old.detail, "联系手机")
      n.fax = get_value_in_xml(old.detail, "传真号码")
      n.email = get_value_in_xml(old.detail, "电子邮件")

      # ["正常",0,"u",100],
      # ["已删除",404,"light",0]
      n.status = 65

      n.summary = get_value_in_xml(old.detail, "备注")
      n.details = old.detail.to_s.gsub("param", "node")
      n.user_id = old.user_id
      n.logs = old.logs.to_s.gsub("param", "node").gsub("&lt;table&gt;", "&lt;table class=&quot;table table-bordered&quot;&gt;")
      n.logs = replace_status_in_logs(n.logs, [["自动生效", 65], ["已删除", 404]])
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      n.category_id = old.category_id
      ca_ids = old.category_id.split(",")
      n.department.items.each do |item|
        i_ca_ids = item.categoryids.split(",")
        n.item_id = item.id if (ca_ids & i_ca_ids).present?
      end

      if n.save
        succ += 1
        p "coordinators succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"coordinators.log"
      end
    end
    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入用户'
  task :users => :environment do
    p "#{begin_time = Time.now} in users....."
    Dragon.table_name = "user_logins"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    set_menu_total = 0
    Dragon.find_each do |old|
      n = User.find_or_initialize_by(id: old.id)

      dep = case old.user_type
      when 1
        Department.find_by(name: "总公司机关")
      when 2
        Department.find_by(old_id: old.dep_purchaser, old_table: "dep_purchaser")
      when 3
        Department.find_by(old_id: old.dep_supplier, old_table: "dep_supplier")
      end
      next if dep.blank?
      n.department_id = dep.id
      n.login = old.login
      n.name = old.user_name
      n.is_admin = old.is_admin == "是" ? 1 : 0
      n.is_personal = 0
      n.password = n.password_confirmation = Base64.decode64(old.password).reverse
      n.email = old.email
      n.mobile = old.mobile
      n.tel = old.telephone
      n.fax = old.fax

      # ["正常",0,"u",100],
      # ["冻结",1,"yellow",100]
      n.status = case old.status
      when "正常"
        65
      when "已冻结"
        12
      else
        404
      end

      n.duty = old.user_duty
      n.details = old.detail.to_s.gsub("param", "node")
      n.logs = old.logs.to_s.gsub("param", "node").gsub("&lt;table&gt;", "&lt;table class=&quot;table table-bordered&quot;&gt;")
      n.logs = replace_status_in_logs(n.logs, [["正常", 65], ["1", 65], ["4", 65], ["已冻结", 12]])
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.save
        # 给用户授权
        if n.department.name != "总公司机关" || [7960, 14058, 146891, 147038, 147037, 136607].include?(n.id)
          n.set_auto_menu
          set_menu_total += 1
        end
        succ += 1
        p ".users succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"users.log"
      end
    end

    p ".users_set_auto_menu succ: #{set_menu_total}"

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入品目'
  task :categories => :environment do
    p "#{begin_time = Time.now} in categories....."

    Dragon.table_name = "zcl_category"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      n = Category.find_or_initialize_by(id: old.id)
      n.name = old.name
      n.yw_type = 6
      n.audit_type = case old.audit_type
      when "1"
        1
      when "2"
        -1
      when "1,2"
        0
      else
        -1
      end

      new_doc = Nokogiri::XML::Document.new()
      new_doc.encoding = "UTF-8"
      new_doc << "<root>"

      old_doc = Nokogiri::XML(old.xygh_param)
      old_doc.xpath("//param").each do |old_node|
        n_node = new_doc.root.add_child("<node>").first
        n_node["name"] = old_node["name"] if old_node.has_attribute? "name"
        n_node["column"] = old_node["alias"] if old_node.has_attribute? "alias"
        n_node["column"] = "model" if n_node["column"] == "name"
        n_node["column"] = "version" if n_node["column"] == "xinghao"

        n_node["column"] = "summary" if n_node["name"] == "基本描述"

        class_arr = []
        class_arr << "required" if old_node.has_attribute?("input") && old_node["input"] == "true"

        case old_node["type"]
        when "字符类型"
          if old_node.has_attribute? "dropdata"
            n_node["data_type"] = 'select'
            n_node["data"] = old_node['dropdata'].split('|').to_s
          end
        when "大文本型"
          n_node["data_type"] = 'textarea'
        when "数字类型"
          class_arr << 'number'
        when "日期类型"
          class_arr << 'date_select'
          class_arr << 'dateISO'
        when "时间类型"
          class_arr << 'datetime_select'
          class_arr << 'datetime'
        end
        n_node["is_key"] = (old_node["alias"] == "unit" ? "否" : old_node["is_key"]) if old_node.has_attribute? "is_key"
        n_node["hint"] = old_node["tips"] if old_node.has_attribute? "tips"
        n_node["class"] = class_arr.join(" ") if class_arr.present?
      end

      n.params_xml = new_doc.to_s.gsub("市场价（元）", "市场价格（元）").gsub("本站报价（元）", "入围价格（元）")

      # ["正常",0,"u",100],
      # ["冻结",1,"yellow",0],
      # ["已删除",404,"red",100]
      n.status = case old.status
      when "正常"
        65
      when "停止"
        12
      when "已删除"
        404
      end

      n.sort = old.sort
      if n.save
        succ += 1
        p ".categories succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"categories.log"
      end
    end

    # 导入层级关系
    Dragon.order("code asc").each do |old|
      n = Category.find_or_initialize_by(id: old.id)
      next if n.ancestry.present?
      n.parent_id = Category.find_by(id: old.parent_id)
      if n.save
        p ".categories ancestry: #{n.ancestry} succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"categories.log"
      end
    end

    # 更新合同模板
    qc = Category.qc.update_all(ht_template: 'qc') if Category.qc.present?
    p "update ht_template qc: #{qc}..."

    gz = Category.gz.update_all(ht_template: 'gz') if Category.gz.present?
    p "update ht_template gz: #{gz}..."

    gc = Category.gc.update_all(ht_template: 'gc') if Category.gc.present?
    p "update ht_template gc: #{gc}..."

    bzw = Category.bzw.update_all(ht_template: 'bzw') if Category.bzw.present?
    p "update ht_template bzw: #{bzw}..."

    bg = Category.bg.each{ |c| c.update(ht_template: 'bg') } if Category.bg.present?
    p "update ht_template bg: #{bg.size}..."

    lj = Category.lj.each{ |c| c.update(ht_template: 'lj') } if Category.lj.present?
    p "update ht_template lj: #{lj.size}..."

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入订单'
  task :orders => :environment do
    p "#{begin_time = Time.now} in orders....."

    Dragon.table_name = "ddcg_info"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      next if old.yw_type == '资产消费'
      next if old.status == "已删除"
      n = Order.find_or_initialize_by(id: old.id)

      next if Order.find_by(sn: old.sn).present?
      n.name = old.project_name.present? ? old.project_name : '-'
      n.sn = old.sn
      n.contract_sn = old.ht_code
      n.buyer_name = old.dep_p_name
      n.payer = get_value_in_xml(old.detail, "发票单位").blank? ? old.dep_p_name : get_value_in_xml(old.detail, "发票单位")

      dep = Department.find_by(name: old.dep_p_name, old_table: "dep_purchaser")
      if dep.blank?
        dep = case old.user_type
        when 1
          Department.find_by(name: "总公司机关")
        when 2
          Department.find_by(old_id: old.user_dep, old_table: "dep_purchaser")
        when 3
          Department.find_by(old_id: old.user_dep, old_table: "dep_supplier")
        end
      end
      n.buyer_id = dep.try(:id)
      n.buyer_code = dep.try(:real_ancestry)

      n.buyer_man = old.dep_p_man.present? ? old.dep_p_man : '-'
      n.buyer_tel = old.dep_p_tel.present? ? old.dep_p_tel : '-'
      n.buyer_mobile = old.dep_p_mobile.present? ? old.dep_p_mobile : '-'
      n.buyer_addr = old.dep_p_add.present? ? old.dep_p_add : '-'

      n.seller_name = old.dep_s_name
      seller_dep = if old.dep_s_id.present?
        Department.find_by(old_id: old.dep_s_id, old_table: "dep_supplier")
      else
        Department.find_by(name: (old.new_name.present? ? old.new_name : old.dep_s_name))
      end
      n.seller_id = seller_dep.try(:id)
      n.seller_code = seller_dep.try(:real_ancestry)

      n.seller_man = old.dep_s_man.present? ? old.dep_s_man : '-'
      n.seller_tel = old.dep_s_tel.present? ? old.dep_s_tel : '-'
      n.seller_mobile = old.dep_s_mobile.present? ? old.dep_s_mobile : '-'
      n.seller_addr = old.dep_s_add.present? ? old.dep_s_add : '-'
      n.budget_money = old.bugget.present? ? (old.bugget < old.total ? old.total : old.bugget) : old.total
      n.total = old.total
      n.deliver_at = get_value_in_xml(old.detail, "送货开始日期").present? ? get_value_in_xml(old.detail, "送货开始日期") : old.created_at
      n.invoice_number = old.invoice_number
      n.summary = get_value_in_xml(old.detail, "备注信息")
      n.user_id = old.user_id
      n.effective_time = old.ysd_time

      # ["未提交",0,"orange",10],
      # ["等待审核",1,"blue",50],
      # ["审核拒绝",2,"red",0],
      # ["自动生效",5,"yellow",60],
      # ["审核通过",6,"yellow",60],
      # ["已完成",3,"u",80],
      # ["未评价",4,"purple",100],
      # ["已删除",404,"light",0],
      # ["等待卖方确认", 10, "aqua", 20],
      # ["等待买方确认", 21, "light-green", 40],
      # ["卖方退回", 15, "orange", 10],
      # ["买方退回", 26, "aqua", 20],
      # ["撤回等待审核", 32, "sea", 30],
      # ["作废等待审核", 43, "sea", 30],
      # ["已作废", 49, "red", 0],
      # ["拒绝撤回", 37, "yellow", 60],
      # ["拒绝作废", 48, "yellow", 60],
      # ["已拆单", 50, "light", 0],
      # ["等待收货", 52, "light", 50]
      #
      n.status = case old.status
      when "未提交"
        0
      when "新增等待审核"
        8
      when "新增审核拒绝"
        7
      when "自动生效"
        2
      when "新增审核通过"
        9
      when "已完成"
        100
      when "已删除"
        404
      when "订单等待确认"
        old.mall_id.present? ? 11 : 3
      when "供应商反馈"
        42
      when "撤回等待审核"
        36
      when "作废等待审核"
        43
      when "已作废"
        47
      when "撤回审核拒绝"
        37
      when "作废审核拒绝"
        44
      when "已拆单"
        5
      when "等待收货"
        11
      else
        404
      end

      n.details = old.detail.to_s.gsub("param", "node")
      n.logs = old.logs.to_s.gsub("param", "node").gsub("&lt;table&gt;", "&lt;table class=&quot;table table-bordered&quot;&gt;")
      n.logs = replace_status_in_logs(n.logs, [["未提交", 0], ["新增等待审核", 8], ["新增审核拒绝", 7], ["自动生效", 2], ["新增审核通过", 9], ["已完成", 100], ["已删除", 404], ["订单等待确认", old.mall_id.present? ? 11 : 3], ["供应商反馈", 42], ["撤回等待审核", 36], ["作废等待审核", 43], ["已作废", 47], ["撤回审核拒绝", 37], ["作废审核拒绝", 44], ["已拆单", 5], ["等待收货", 11], ["需求未提交", 0], ["需求等待审核", 15], ["需求审核拒绝", 14], ["接受投标", 16], ["接受报价", 16], ["结果等待审核", 22], ["结果审核拒绝", 25], ["确定中标人", 23], ["废标等待审核", 29], ["废标审核拒绝", 32], ["已删除", 404], ["已废标", 33], ["撤销等待审核", 36], ["撤销审核拒绝", 37], ["已撤销", 35]])
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      n.yw_type = Dictionary.yw_type.key(old.yw_type)
      n.yw_type = 'dscg' if old.yw_type == "协议供货" && old.mall_id.present?

      n.sfz = get_value_in_xml(old.detail, "身份证号码")
      n.deliver_fee = get_value_in_xml(old.detail, "运费（元）")
      n.other_fee = get_value_in_xml(old.detail, "其他费用（元）")
      n.other_fee_desc = get_value_in_xml(old.detail, "其他费用说明")
      # n.comment_total = old.comment_total
      # n.comment_detail = old.comment_detail.to_s.gsub("param", "node")
      n.audit_user_id = get_user_id_in_audit_log(old)
      n.mall_id = old.mall_id
      if n.yw_type == 'wsjj'
        wsjj = BidProject.find_by(code: n.sn)
        n.mall_id = wsjj.try(:id)
      end

      n.ht_template = case old.category_id
      when 154, 155
        "bzw"
      when 50, 883
        "gc"
      when 48, 22, 2
        "lj"
      when 13, 4
        "qc"
      when 56
        "gz"
      when 44
        "ds"
      else
        "bg"
      end

      if n.save
        # 协议供货 等待审核
        # if n.yw_type == 'xygh' && n.status == 8
        #   n.update(rule_step: '卖方确认')
        #   n.update(rule_step: n.reload.get_next_step["name"])
        # end
        n.update(rule_step: 'done') if [2, 9, 100].include?(n.status)
        if n.status == 8
          node = Nokogiri::XML(n.logs).css('node').last
          if node.present?
            c_step = node["操作内容"]
            c_remark = node["备注"]
            if c_step == '分公司审核'
              step = c_remark.include?("确认并转向总公司审核") ? '总公司审核' : '分公司审核'
            end
            if c_step == '总公司审核'
              step = '总公司审核'
            end
          end
        end
        n.update(rule_step: step) if step.present?
        succ += 1
        p ".orders succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"orders.log"
      end
    end
    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入订单产品'
  task :orders_items => :environment do
    p "#{begin_time = Time.now} in orders_items....."

    old_table_name = "ddcg_product"
    Dragon.table_name = old_table_name
    max = 10 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      next if old.category_id == 55
      n = OrdersItem.find_or_initialize_by(old_id: old.id, old_table: old_table_name)
      next if n.id.present?

      n.order_id = old.ddcg_info_id
      n.category_id = old.zcl_category_id
      ca = Category.find_by(id: old.zcl_category_id)
      n.category_code = ((ca.present? && ca.ancestry.present?) ? ca.ancestry : 0)
      n.category_name = old.product_type
      n.product_id = old.product_id.blank? ? 0 : old.product_id
      n.brand = old.product_brand
      n.model = old.product_name
      n.version = old.product_xinghao
      n.unit = old.unit
      n.market_price = old.market_price
      n.bid_price = old.bid_price
      n.price = old.purchase_price.present? ? old.purchase_price : 0
      n.quantity = old.purchase_num.present? ? old.purchase_num : 0
      n.total = old.total.present? ? old.total : (old.purchase_price * old.purchase_num)
      n.summary = old.product_description
      n.details = old.detail.to_s.gsub("param", "node")
      n.created_at = old.created_at
      n.updated_at = old.updated_at
      # n.comment_detail = old.comment_detail.to_s.gsub("param", "node")

      if n.save
        succ += 1
        p ".orders_items succ: #{succ}/#{total} #{old_table_name}_id: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"orders_items.log"
      end
    end

    old_table_name = "ddcg_spare"
    Dragon.table_name = old_table_name
    max = 10 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      next if old.category_id == 55
      n = OrdersItem.find_or_initialize_by(old_id: old.id, old_table: old_table_name)
      next if n.id.present?

      n.order_id = old.ddcg_info_id
      n.category_id = old.zcl_category_id
      ca = Category.find_by(id: old.zcl_category_id)
      n.category_code = ((ca.present? && ca.ancestry.present?) ? ca.ancestry : 0)
      n.category_name = old.product_type
      n.product_id = old.product_id.blank? ? 0 : old.product_id
      n.brand = old.product_brand
      n.model = old.product_name
      n.version = old.product_xinghao
      n.unit = old.unit
      n.market_price = old.market_price
      n.bid_price = old.bid_price
      n.price = old.purchase_price.present? ? old.purchase_price : 0
      n.quantity = old.purchase_num.present? ? old.purchase_num : 0
      n.total = old.total.present? ? old.total : (old.purchase_price * old.purchase_num)
      n.summary = old.product_description
      n.details = old.detail.to_s.gsub("param", "node")
      n.created_at = old.created_at
      n.updated_at = old.updated_at
      # n.comment_detail = old.comment_detail.to_s.gsub("param", "node")

      if n.save
        succ += 1
        p ".orders_items succ: #{succ}/#{total} #{old_table_name}_id: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"orders_items.log"
      end
    end
    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc "导入订单审核的待办事项"
  task :order_tqs => :environment do
    p "#{begin_time = Time.now} in order_tqs....."

    # 等待审核、等待卖方确认
    orders = Order.where(status: [8, 3])
    succ = clean_left = 0
    clean_id = []
    orders.each do |o|
      next if o.task_queues.present?
      # 清除历史遗留项目
      if o.status == 8 and o.created_at < '2015-01-01'
        clean_left += 1
        o.change_status_and_write_logs("已删除", save_logs(o.logs, "删除", 404, "清除历史遗留项目"))
        clean_id << o.id
      else
        # 插入待办事项
        o.create_task_queue(o.audit_user_id)
        if o.reload.task_queues.present?
          succ += 1
          p ".order_tqs succ: #{succ}/#{orders.size} order_id: #{o.id}"
        else
          log_p "[error]order_id: #{o.id} | #{o.errors.full_messages}" ,"order_tqs.log"
        end
      end
    end

    p "清除历史遗留项目: #{clean_left}, id: #{clean_id.join(', ')}"

    tqs = TaskQueue.where(class_name: "Order")
    p ".task_queues succ: #{tqs.size} [user_id, dep_id]: #{tqs.group(:user_id, :dep_id).count(:id)}"

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc "订单"
  task :os => :environment do
    Rake::Task["data:orders"].invoke
    p "========================================================="
    Rake::Task["data:orders_items"].invoke
    p "========================================================="
    Rake::Task["data:order_tqs"].invoke
  end

  desc '创建文章公告类别'
  task :article_catalogs => :environment do
    p "#{begin_time = Time.now} in article_catalogs....."

    arr = ["招标公告", "招标结果公告", "图片新闻", "重要通知"]
    max = 1000 ; succ = i = 0
    total = arr.count
    arr.each do |name|
      n = ArticleCatalog.find_or_initialize_by(name: name)
      if n.save
        succ += 1
        p ".article_catalogs succ: #{succ}/#{total}"
      else
        log_p "[error] #{n.errors.full_messages}" ,"article_catalogs.log"
      end
    end
    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入文章公告'
  task :articles => :environment do
    p "#{begin_time = Time.now} in articles....."

    Dragon.table_name = "zcl_article"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    audit_total = 0
    Dragon.find_each do |old|
      old_catalog = old.catalog.split(",")
      next if (["图片新闻", "工作动态", "服务消息", "采购公告"] & old_catalog).blank?

      n = Article.find_or_initialize_by(id: old.id)
      n.title = old.title
      n.user_id = old.user_id
      n.publish_time = old.publish_time
      n.tags = old.keywords
      n.new_days = old.newdays
      #  [[0, "不置顶"], [1, "普通置顶"], [2, "标红置顶"]]
      n.top_type = case old.top_type
      when "未置顶"
        0
      when "普通置顶"
        1
      when "红色置顶"
        2
      else
        0
      end
      # ["暂存", 0, "orange", 50],
      # ["等待审核", 1, "orange", 90],
      # ["已发布", 2, "u", 100],
      # ["审核拒绝",3,"red",0],
      # ["已删除", 404, "red", 0]
      n.status = case old.status
      when "审核通过"
        16
      when "未提交"
        0
      when "审核拒绝"
        7
      when "已删除"
        404
      when "等待审核"
        8
      else
        0
      end
      n.username = old.user_name
      n.content = old.content
      n.hits = old.hits
      n.department_id = User.find_by(id: old.user_id).try(:department_id)
      # ["图片新闻", "图片新闻,工作动态", "工作动态", "服务消息", "采购公告", "采购公告,服务消息"]
      # ["招标公告", "招标结果公告", "图片新闻", "重要通知"]
      ca_name = []
      ca_name << "重要通知" if (["工作动态", "服务消息"] & old_catalog).present?
      ca_name << (old.title.include?("结果") ? "招标结果公告" : "招标公告") if old_catalog.include?("采购公告")
      ca_name << "图片新闻" if old_catalog.include?"图片新闻"
      if ca_name.present?
        ca_ids = []
        ca_name.each { |e| ca_ids << ArticleCatalog.find_by(name: e).try(:id) }
        n.catalogids = ca_ids.compact.join(",")
      end

      xml = old.detail.to_s.gsub("param", "node")
      if xml.present?
        doc = Nokogiri::XML(xml)
      else
        doc = Nokogiri::XML::Document.new
        doc.encoding = "UTF-8"
        doc << "<root>"
      end
      node = doc.root.add_child("<node>").first
      node["name"] = "所属栏目"
      node["value"] = ca_name.join(",")
      n.details = doc.to_s
      n.logs = old.logs.to_s.gsub("param", "node").gsub("&lt;table&gt;", "&lt;table class=&quot;table table-bordered&quot;&gt;")
      n.logs = replace_status_in_logs(n.logs, [["审核通过", 16], ["未提交", 0], ["审核拒绝", 7], ["已删除", 404], ["等待审核", 8]])
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.save
        # 如果状态是等待审核 插入待办事项
        if n.status == 8
          audit_total += 1
          n.create_task_queue(get_user_id_in_audit_log(old))
        end
        succ += 1
        p ".articles succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"articles.log"
      end
    end

    tqs = TaskQueue.where(class_name: "Article")
    p ".articles_audit succ: #{tqs.size}/#{audit_total} [user_id, dep_id]: #{tqs.group(:user_id, :dep_id).count(:id)}"

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入下载栏目、用户指南'
  task :faqs => :environment do
    p "#{begin_time = Time.now} in faqs....."

    Dragon.table_name = "zcl_article"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      next unless ['下载栏目','供应商须知','用户指南','采购人须知'].include?(old.catalog)

      n = Faq.find_or_initialize_by(id: old.id)

      # { yjjy: "意见建议" , cjwt: "常见问题" , cgzn: "采购指南" , xzzx: "下载中心" , zcfg: "政策法规"}
      n.catalog = case old.catalog
      when "下载栏目"
        "xzzx"
      when "供应商须知", "采购人须知", "用户指南"
        "cgzn"
      end

      n.title = old.title
      n.content = old.content
      n.user_id = old.user_id
      # ["暂存",0,"orange",50],
      # ["已发布",1,"u",100],
      # ["未回复",2,"blue",80],
      # ["已回复",3,"sea",100],
      # ["已删除",404,"light",0]
      # n.status = case old.status
      # when "审核通过"
      #   1
      # when "未提交", "审核拒绝"
      #   0
      # when "已删除"
      #   404
      # else
      #   0
      # end
      n.status = 16
      n.details = old.detail.to_s.gsub("param", "node")
      n.logs = old.logs.to_s.gsub("param", "node").gsub("&lt;table&gt;", "&lt;table class=&quot;table table-bordered&quot;&gt;")
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.save
        succ += 1
        p ".faqs succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"faqs.log"
      end
    end
    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入网上竞价需求主表'
  task :bid_projects => :environment do
    p "#{begin_time = Time.now} in bid_projects....."

    Dragon.table_name = "zcl_xq_info"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      next if BidProject.find_by(code: old.project_code).present?
      n = BidProject.find_or_initialize_by(id: old.id)

      n.buyer_dep_name = old.dep_p_name
      n.invoice_title = get_value_in_xml(old.detail, "发票单位").blank? ? old.dep_p_name : get_value_in_xml(old.detail, "发票单位")
      n.buyer_name = old.dep_p_man
      n.buyer_phone = old.dep_p_tel
      n.buyer_mobile = old.dep_p_mobile
      n.buyer_add = old.dep_p_add
      # [[1, "明标"], [0, "暗标"]]
      n.lod = Dictionary.lod.find{|e| e[1] == old.show_price}.try(:first)
      n.end_time = old.end_time
      n.budget_money = old.budget
      n.req = get_value_in_xml(old.detail, "供应商资质要求")
      n.remark = get_value_in_xml(old.detail, "备注信息")

      n.name = old.project_name
      n.code = old.project_code
      n.user_id = old.user_id
      dep = Department.find_by(old_id: old.user_dep, old_table: "dep_purchaser")
      n.department_id = dep.try(:id)
      n.department_code = dep.try(:real_ancestry)

      # ["暂存", 0, "orange", 20],
      # ["需求等待审核", 1, "blue", 40],
      # ["需求审核拒绝",3,"red", 0],
      # ["已发布", 2, "orange", 50],
      # ["结果等待审核", 4, "sea", 70],
      # ["结果审核拒绝",5,"red", 50],
      # ["确定中标人", 12, "u", 100],
      # ["废标等待审核", 6, "sea", 70],
      # ["废标审核拒绝",7,"red", 50],
      # ["已废标", -1, "red", 100],
      # ["已删除", 404, "light", 0]
      n.status = case old.status
      when "需求未提交"
        0
      when "需求等待审核"
        15
      when "需求审核拒绝"
        14
      when "接受报价"
        16
      when "结果等待审核"
        22
      when "结果审核拒绝"
        25
      when "确定中标人"
        23
      when "废标等待审核"
        29
      when "废标审核拒绝"
        32
      when "已废标"
        33
      else
        404
      end

      n.details = old.detail.to_s.gsub("param", "node")
      n.logs = old.logs.to_s.gsub("param", "node").gsub("&lt;table&gt;", "&lt;table class=&quot;table table-bordered&quot;&gt;")
      n.logs = replace_status_in_logs(n.logs, [["需求未提交", 0], ["需求等待审核", 15], ["需求审核拒绝", 14], ["接受报价", 16], ["结果等待审核", 22], ["结果审核拒绝", 25], ["确定中标人", 23], ["废标等待审核", 29], ["废标审核拒绝", 32], ["已删除", 404], ["已废标", 33]])
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.status == 33
        doc = Nokogiri::XML(n.logs)
        node = doc.present? ? doc.xpath('//node[@操作内容="选择废标"]').last : ''
        arr = node.present? ? node["备注"].split("操作理由：") : []
        reason = arr.size == 2 ? arr.last : ''
        n.reason = reason
      end

      if n.save
        n.update(rule_id: Rule.find_by(yw_type: 'wsjj_jg').try(:id), rule_step: 'start') if [22, 29].include?(n.status)
        succ += 1
        p ".bid_projects succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"bid_projects.log"
      end
    end
    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入网上竞价需求产品从表'
  task :bid_items => :environment do
    p "#{begin_time = Time.now} in bid_items....."

    old_table_name = "zcl_xq_product"
    Dragon.table_name = old_table_name
    max = 10 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      n = BidItem.find_or_initialize_by(id: old.id)

      n.category_id = old.zcl_category_id
      n.bid_project_id = old.zcl_xq_info_id
      n.category_name = old.product_type
      n.brand_name = old.product_brand
      n.xh = old.product_xinghao
      n.num = old.purchase_num
      n.unit = old.unit
      n.can_other = old.is_allow == "是" ? 1 : 0
      n.req = old.product_description
      n.remark = get_value_in_xml(old.detail, "备注")

      n.details = old.detail.to_s.gsub("param", "node")
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.save
        succ += 1
        p ".bid_items succ: #{succ}/#{total} #{old_table_name}_id: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"bid_items.log"
      end
    end

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入网上竞价报价主表'
  task :bid_project_bids => :environment do
    p "#{begin_time = Time.now} in bid_project_bids....."

    old_table_name = "zcl_bid_info"
    Dragon.table_name = old_table_name
    max = 10 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      n = BidProjectBid.find_or_initialize_by(id: old.id)

      n.bid_project_id = old.zcl_xq_info_id
      n.com_name = old.dep_name
      n.username = old.dep_s_man
      n.tel = old.dep_s_tel
      n.mobile = old.dep_s_mobile
      n.add = old.dep_s_add
      n.user_id = old.user_id
      n.total = old.total.blank? ? 0 : old.total
      n.bid_time = old.bid_time
      n.department_id = Department.find_by(old_id: old.user_dep, old_table: "dep_supplier").try(:id)
      n.is_bid = old.is_bid == "是" ? 1 : 0

      n.details = old.detail.to_s.gsub("param", "node")
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.save
        succ += 1
        p ".bid_project_bids succ: #{succ}/#{total} #{old_table_name}_id: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"bid_project_bids.log"
      end
    end

    bids = BidProjectBid.where(is_bid: true)
    succ = 0
    bids.each do |e|
      doc = Nokogiri::XML(e.bid_project.logs)
      node = doc.present? ? doc.xpath('//node[@操作内容="选择中标人"]').last : ''
      arr = node.present? ? node["备注"].split("操作理由：") : []
      reason = arr.size == 2 ? arr.last : ''
      if e.bid_project.update(bid_project_bid_id: e.id, reason: reason)
        succ += 1
        p ".update bid_project.bid_project_bid_id succ: #{succ}/#{bids.size} bid_project_id: #{e.bid_project_id}"
      else
        log_p "[error]bid_project_id: #{e.bid_project_id} | #{n.errors.full_messages}" ,"update_bid_project_bid_id.log"
      end
    end

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入网上竞价报价产品从表'
  task :bid_item_bids => :environment do
    p "#{begin_time = Time.now} in bid_item_bids....."

    old_table_name = "zcl_bid_product"
    Dragon.table_name = old_table_name
    max = 10 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      n = BidItemBid.find_or_initialize_by(id: old.id)

      n.brand_name = old.product_brand
      n.xh = old.product_xinghao
      n.bid_project_bid_id = old.zcl_bid_info_id
      n.price = old.purchase_price.blank? ? 0 : old.purchase_price
      n.total = old.total.blank? ? 0 : old.total
      n.req = old.product_description
      n.remark = get_value_in_xml(old.detail, "备注")
      n.details = old.detail.to_s.gsub("param", "node")

      n.bid_project_id = n.bid_project_bid.try(:bid_project).try(:id)
      n.user_id = n.bid_project_bid.try(:user_id)
      items = n.bid_project_bid.try(:bid_project).try(:items)
      if items.present?
        n.bid_item_id = items.first.id if items.size == 1
        n_item = items.find{ |i| i.brand_name == n.brand_name && i.xh == n.xh && i.req == n.req }
        n.bid_item_id = n_item.id if n_item.present?
        n.bid_item_id = nil if BidItemBid.find_by(bid_item_id: n.bid_item_id, user_id: n.user_id).present?
      end

      if n.save
        succ += 1
        p ".bid_item_bids succ: #{succ}/#{total} #{old_table_name}_id: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"bid_item_bids.log"
      end
    end

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc "导入网上竞价审核的待办事项"
  task :bid_project_tqs => :environment do
    p "#{begin_time = Time.now} in bid_project_tqs....."

    bid_projects = BidProject.where(status: [15, 22, 29])
    succ = clean_left = 0
    clean_id = []
    bid_projects.each do |o|
      next if o.task_queues.present?
      # 清除历史遗留项目
      if o.status == 15 and o.created_at < '2015-01-01'
        clean_left += 1
        o.change_status_and_write_logs("已删除", save_logs(o.logs, "删除", 404, "清除历史遗留项目"))
        clean_id << o.id
      else
        # 插入待办事项
        o.create_task_queue
        if o.reload.task_queues.present?
          succ += 1
          p ".bid_project_tqs succ: #{succ}/#{bid_projects.size} bid_project_id: #{o.id}"
        else
          log_p "[error]bid_project_id: #{o.id} | #{o.errors.full_messages}" ,"bid_project_tqs.log"
        end
      end
    end

    p "清除历史遗留项目: #{clean_left}, id: #{clean_id.join(', ')}"

    tqs = TaskQueue.where(class_name: "BidProject")
    p ".task_queues succ: #{tqs.size} [user_id, dep_id]: #{tqs.group(:user_id, :dep_id).count(:id)}"

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc "网上竞价"
  task :bids => :environment do
    Rake::Task["data:bid_projects"].invoke
    p "========================================================="
    Rake::Task["data:bid_items"].invoke
    p "========================================================="
    Rake::Task["data:bid_project_bids"].invoke
    p "========================================================="
    Rake::Task["data:bid_item_bids"].invoke
    p "========================================================="
    Rake::Task["data:bid_project_tqs"].invoke
  end

  desc '导入资产划转'
  task :transfers => :environment do
    p "#{begin_time = Time.now} in transfers....."

    Dragon.table_name = "zcl_transfer_out"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      n = Transfer.find_or_initialize_by(id: old.id)
      n.name = old.project_name
      n.sn = old.sn
      dep = Department.find_by(old_id: old.user_dep, old_table: "dep_purchaser")
      n.department_id = dep.try(:id)
      n.dep_name = old.dep_p_name
      n.dep_code = dep.try(:real_ancestry)
      n.dep_man = get_value_in_xml(old.detail, "联系人姓名")
      n.dep_tel = get_value_in_xml(old.detail, "联系人电话")
      n.dep_mobile = get_value_in_xml(old.detail, "联系人手机")
      n.dep_addr = get_value_in_xml(old.detail, "单位地址")
      n.total = old.budget
      n.submit_time = old.submit_time
      n.user_id = old.user_id
      # ["暂存",0,"orange",50],
      # ["已发布",1,"blue",100],
      # ["已删除",404,"light",0]
      n.status = case old.status
      when "未提交"
        0
      when "已发布"
        16
      else
        404
      end
      n.details = old.detail.to_s.gsub("param", "node")
      n.logs = old.logs.to_s.gsub("param", "node").gsub("&lt;table&gt;", "&lt;table class=&quot;table table-bordered&quot;&gt;")
      n.logs = replace_status_in_logs(n.logs, [["未提交", 0], ["已发布", 16], ["已报废", 404]])
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      # [[0,'完好可使用'],[1,'需要维修'], [2,'提供配件']]
      p_status = case old.product_status
      when "完好可使用"
        0
      when "需要维修"
        1
      when "提供配件"
        2
      end
      ca = Category.find_by(id: old.zcl_category_id)
      n.items.build(category_id: old.zcl_category_id, category_name: old.zcl_category_name, category_code: ca.try(:ancestry),
        unit: old.unit, original_price: old.original_value, net_price: old.net_value, transfer_price: old.budget,
        num: old.product_num, product_status: p_status, created_at: old.created_at,
        description: get_value_in_xml(old.detail, "技术规格或产品说明"), updated_at: old.updated_at,
        summary: get_value_in_xml(old.detail, "备注"), details: old.detail.to_s.gsub("param", "node")
      )

      if n.save
        succ += 1
        p ".transfers succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"transfers.log"
      end

    end
    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end

  desc '导入日常费用类别'
  task :daily_categories => :environment do
    p "#{begin_time = Time.now} in daily_categories....."

    Dragon.table_name = "zcl_cost_category"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      n = DailyCategory.find_or_initialize_by(id: old.id)
      n.name = old.name
      n.status = 65
      n.sort = old.sort

      if n.save
        succ += 1
        p ".daily_categories succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"daily_categories.log"
      end
    end

    # 导入层级关系
    Dragon.order("code asc").each do |old|
      n = DailyCategory.find_or_initialize_by(id: old.id)
      next if n.ancestry.present?
      n.parent_id = DailyCategory.find_by(id: old.parent_id)
      if n.save
        p ".daily_categories ancestry: #{n.ancestry} succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"daily_categories.log"
      end
    end

    p "#{end_time = Time.now} end... #{(end_time - begin_time)/60} min "
  end


  # 输出日志到文件和控制台
  def self.log_p(msg, log_path = "data.log")
    @logger ||= Logger.new(Rails.root.join('log', log_path))
    @logger.info msg
  end

  # 取detail里面 某字段的值
  def self.get_value_in_xml(xml, name)
    doc = Nokogiri::XML(xml)
    node = doc.at_css("//[@name='#{name}']")
    return node.present? ? node["value"] : ''
  end

  # 取audit_log里面的拟审核人
  def self.get_user_id_in_audit_log(old)
    doc = Nokogiri::XML(old.audit_log)
    node = doc.at_css("//[@状态='待办']")
    str = node.present? ? node["拟审核人"] : ''
    # "汪喜波(id:146891)[确认审核]"
    idl = str.index(":")
    idr = str.index(")")
    return (idl.present? && idr.present?) ? str[(idl+1)...idr] : ''
  end

  # 清除历史遗留数据 插入日志
  def save_logs(xml, action, status, remark)
    user = User.find_by(login: 'zcl001')
    node = Nokogiri::XML(xml).root.add_child("<node>").first
    node["操作时间"] = Time.now.to_s(:db)
    node["操作人ID"] = user.id.to_s
    node["操作人姓名"] = user.name.to_s
    node["操作人单位"] = user.department.nil? ? "暂无" : user.department.name.to_s
    node["操作内容"] = action
    node["当前状态"] = status
    node["备注"] = remark
    return node.to_s
  end

  # 替换日志中的中文状态 arr = [["正常", 65 ], ["已删除", 404]]
  def replace_status_in_logs(logs, arr)
    arr.each do |a|
      logs.gsub!("当前状态=\"#{a[0]}\"", "当前状态=\"#{a[1]}\"")
      logs.gsub!("当前状态='#{a[0]}'", "当前状态='#{a[1]}'")
    end
    return logs
  end
end
