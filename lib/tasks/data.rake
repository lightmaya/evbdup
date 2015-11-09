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
      d.name = old.name
      d.is_secret = old.secret == "是"
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
      d.sort = old.sort
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
        p ".zcl_item_factory succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]zcl_item_factory_old_id: #{old.id} | #{n.errors.full_messages}" ,"data_items.log"
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

      n.category_id = old.category_id
      n.user_id = old.user_id
      n.logs = old.logs.to_s.gsub("param", "node")
      n.created_at = old.created_at
      n.updated_at = old.updated_at

      if n.save
        succ += 1
        p ".zcl_item_factory succ: #{succ}/#{total} old: #{old.id}"
      else
        log_p "[error]zcl_item_factory_old_id: #{old.id} | #{n.errors.full_messages}" ,"data_items.log"
      end
    end
  end

  # 输出日志到文件和控制台
  def self.log_p(msg, log_path = "data.log")
    @logger ||= Logger.new(Rails.root.join('log', log_path))
    @logger.info msg 
  end

end