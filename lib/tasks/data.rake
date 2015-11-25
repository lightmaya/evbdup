# -*- encoding : utf-8 -*-
namespace :data do
  desc '导入协议供货产品'
  task :products => :environment do
    Dragon.table_name = "zcl_product"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |zcl_product|
      i += 1
      pr = Product.find_or_initialize_by(id: zcl_product.id)
      pr.category_id = zcl_product.zcl_category_id
      pr.category_code = pr.category.try(:ancestry)
      pr.item_id = zcl_product.item_id
      pr.brand = zcl_product.brand
      pr.model = zcl_product.name
      pr.version = zcl_product.xinghao
      pr.unit = zcl_product.unit
      pr.market_price = zcl_product.market_price
      pr.bid_price = zcl_product.bid_price
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
        1
      when "新增等待审核"
        2
      when "新增审核拒绝"
        3
      when "已删除"
        404
      when "已撤销", "撤销审核通过"
        4
      end
      pr.details = zcl_product.detail.to_s.gsub("param", "node")
      pr.logs = zcl_product.logs.to_s.gsub("param", "node")
      pr.created_at = zcl_product.created_at
      pr.updated_at = zcl_product.updated_at
      if pr.save
        succ += 1
        p "succ: #{succ}/#{total} zcl_product_id: #{zcl_product.id}"
      else
        log_p "[error]zcl_product_id: #{zcl_product.id} | #{pr.errors.full_messages}" ,"data_products.log"
      end
      # break if i > max
    end
  end

  desc '导入单位'
  task :departments => :environment do
    p "in departments....."

    if Department.first.blank?
      [["采购单位", "1", 2], ["供应商", "1", 3], ["监管机构", "1", 1], ["评审专家", "1", 4]].each do |option|
        Department.find_or_create_by(:name => option[0], :status => option[1], id: option[2])
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
        1
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
      d.logs = old.logs.to_s.gsub("param", "node")
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
        1
      when "已删除"
        404
      when "审核不通过"
        3
      when "注册未完成"
        0
      when "已冻结"
        4
      when "等待审核"
        2
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
      d.logs = old.logs.to_s.gsub("param", "node")
      d.created_at = old.created_at
      d.updated_at = old.updated_at

      d.comment_total = old.comment_total
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
        succ += 1
        p ".departments succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{d.errors.full_messages}" ,"departments.log"
      end
    end
  end

  desc '导入协议供货项目'
  task :items => :environment do
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
        2
      when "已停止"
        3
      when "已删除"
        404
      when "有效"
        1
      else
        404
      end


      n.details = old.detail.to_s.gsub("param", "node")
      n.logs = old.logs.to_s.gsub("param", "node")
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.save
        succ += 1
        p ".items succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"data_items.log"
      end

    end

    old_table_name = "zcl_item_factory" 
    Dragon.table_name = old_table_name
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
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
    
  end

  desc '导入代理商'
  task :agents => :environment do
    Dragon.table_name = "zcl_agents"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      n = Agent.find_or_initialize_by(id: old.id)
      new_dep = Department.find_by(old_id: old.user_dep, old_table: "dep_supplier")
      next if new_dep.blank?
      n.department_id = new_dep.id
      n.name = old.agent_name
      new_dep = Department.find_by(old_id: old.agent_id, old_table: "dep_supplier")
      next if new_dep.blank?
      n.agent_id = new_dep.id
      n.area_id = old.city
      # ["正常",0,"u",100],
      # ["已删除",404,"light",0]
      n.status = case old.status
      when "自动生效", "新增审核通过"
        0
      when "已暂停", "新增审核拒绝", "未提交", "新增等待审核"
        404
      else
        404
      end

      n.user_id = old.user_id
      n.logs = old.logs.to_s.gsub("param", "node")
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.save
        succ += 1
        p "agents succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"agents.log"
      end
    end
  end

  desc '导入用户'
  task :users => :environment do
    Dragon.table_name = "user_logins"
    max = 1000 ; succ = i = 0
    total = Dragon.count
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
        0
      when "已冻结"
        1
      else
        404
      end

      n.duty = old.user_duty
      n.details = old.detail.to_s.gsub("param", "node")
      n.logs = old.logs.to_s.gsub("param", "node")
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.save
        # 给用户授权
        n.set_auto_menu
        succ += 1
        p ".users succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"users.log"
      end
    end
  end

  desc '导入品目'
  task :categories => :environment do
    p "in categories....."

    Dragon.table_name = "zcl_category" 
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      n = Category.find_or_initialize_by(id: old.id)
      n.name = old.name
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

      n.params_xml = new_doc.to_s

      # ["正常",0,"u",100],
      # ["冻结",1,"yellow",0],
      # ["已删除",404,"red",100]
      n.status = case old.status
      when "正常"
        0
      when "停止"
        1
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
    Category.qc.update_all(ht_template: 'qc') if Category.qc.present?
    Category.bg.update_all(ht_template: 'bg') if Category.bg.present?
    Category.lj.update_all(ht_template: 'lj') if Category.lj.present?
  end

  desc '导入订单'
  task :orders => :environment do
    Dragon.table_name = "user_logins"
    max = 1000 ; succ = i = 0
    total = Dragon.count
    Dragon.find_each do |old|
      next if old.yw_type == '资产消费'
      n = Order.find_or_initialize_by(id: old.id)
      n.name = old.project_name
      n.sn = old.sn
      n.contract_sn = old.ht_code
      n.buyer_name = old.dep_p_name 
      n.payer = get_value_in_xml(old.detail, "发票单位")
      # ================================begin======================================
      dep = case old.user_type
      when 1
        Department.find_by(name: "总公司机关")
      when 2
        Department.find_by(old_id: old.user_dep, old_table: "dep_purchaser")
      when 3
        Department.find_by(old_id: old.user_dep, old_table: "dep_supplier")
      end

      n.buyer_id = dep.try(:id)
      n.buyer_code = dep.real_ancestry
      # ==================================end=====================================
      n.buyer_man = old.dep_p_man
      n.buyer_tel = old.dep_p_tel 
      n.buyer_mobile = old.dep_p_mobile 
      n.buyer_addr = old.dep_p_add

      n.seller_name = old.dep_s_name
      seller_dep = if old.dep_s_id.present?
        Department.find_by(old_id: old.dep_s_id, old_table: "dep_supplier")
      else
        Department.find_by(name: (old.new_name.present? ? old.new_name : old.dep_s_name))
      end
      n.seller_id = seller_dep.try(:id)
      n.seller_code = seller_dep.try(:real_ancestry)

      n.seller_man = old.dep_s_man
      n.seller_tel = old.dep_s_tel
      n.seller_mobile = old.dep_s_mobile
      n.seller_addr = old.dep_s_add
      n.budget_money = old.bugget
      n.total = old.total
      n.deliver_at = get_value_in_xml(old.detail, "送货开始日期")
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
      # ["已拆单", 50, "light", 0]
      # 
      n.status = case old.status
      when "未提交"
        0
      when "新增等待审核"
        1
      when "新增审核拒绝"
        2
      when "自动生效"
        5
      when "新增审核通过"
        6
      when "已完成"
        3
      when "已删除"
        404
      when "订单等待确认"
        10
      when "供应商反馈"
        15
      when "撤回等待审核"
        32
      when "作废等待审核"
        43
      when "已作废"
        49
      when "撤回审核拒绝"
        37
      when "作废审核拒绝"
        48
      when "已拆单"
        50
      else
        404
      end

      n.details = old.detail.to_s.gsub("param", "node")
      n.logs = old.logs.to_s.gsub("param", "node")
      n.created_at = old.created_at
      n.updated_at = old.updated_at
      n.yw_type = Dictionary.yw_type.key(old.yw_type)
      n.sfz = get_value_in_xml(old.detail, "身份证号码")
      n.deliver_fee = get_value_in_xml(old.detail, "运费（元）")
      n.other_fee = get_value_in_xml(old.detail, "其他费用（元）")
      n.other_fee_desc = get_value_in_xml(old.detail, "其他费用说明")

      if n.save
        # 给用户授权
        n.set_auto_menu
        succ += 1
        p ".users succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]old_id: #{old.id} | #{n.errors.full_messages}" ,"users.log"
      end
    end
  end


  # 输出日志到文件和控制台
  def self.log_p(msg, log_path = "data.log")
    @logger ||= Logger.new(Rails.root.join('log', log_path))
    @logger.info msg 
  end

  def self.get_value_in_xml(xml, name)
    doc = Nokogiri::XML(xml)
    doc.at_css("//[@name='#{name}]")["value"]
  end


end