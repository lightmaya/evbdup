# -*- encoding : utf-8 -*-
require "ancestry"

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# 初始化区域数据
if Area.first.blank?
  source = File.new("#{Rails.root}/db/sql/areas.sql", "r")
  line = source.gets
  ActiveRecord::Base.connection.execute(line)
  Area.rebuild_depth_cache!
end

if Department.first.blank?
  [["执行机构","1"],["采购单位", "1"], ["供应商", "1"], ["监管机构", "1"], ["评审专家", "1"]].each do |option|
    Department.create(:name => option[0], :status => option[1])
  end
end

if Menu.first.blank?

  yw = Menu.create(:name => "业务管理", :icon => "fa-tasks", :is_auto => true, :is_show => true)
# ----订单中心-----------------------------------------------------------------------------------------
  Menu.create(:name => "订单中心", :route_path => "/kobe/orders", :can_opt_action => "Order|read", :is_show => true, :parent => yw)
# ----品目管理-----------------------------------------------------------------------------------------
  category = Menu.create(:name => "品目管理", :route_path => "/kobe/categories", :can_opt_action => "Category|read", :is_show => true, :parent => yw)
  [ ["增加品目", "Category|create"], 
    ["修改品目", "Category|update"], 
    ["删除品目", "Category|update_destroy"],
    ["冻结品目", "Category|freeze"],
    ["恢复品目", "Category|recover"], 
    ["移动品目", "Category|move"]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => category)
  end

# ----入围项目管理-------------------------------------------------------------------------------------
  item = Menu.create(:name => "入围项目管理", :route_path => "/kobe/items", :can_opt_action => "Item|read", :is_show => true, :parent => yw)
  [ ["增加项目", "Item|create"], 
    ["修改项目", "Item|update"], 
    ["提交项目", "Item|commit"], 
    ["停止项目", "Item|pause"], 
    ["恢复项目", "Item|recover"], 
    ["删除项目", "Item|update_destroy"]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => item)
  end

# ----入围产品管理-------------------------------------------------------------------------------------
  item_manage = Menu.create(:name => "入围产品管理", :is_show => true, :parent => yw)
  Menu.create(:name => "我的入围项目", :route_path => "/kobe/items/list", :can_opt_action => "Item|list", :is_show => true, :parent => item_manage)
  item_list = Menu.create(:name => "我的入围产品", :route_path => "/kobe/products", :can_opt_action => "Product|read", :is_show => true, :parent => item_manage)
  [ ["查看项目", "Item|show"],
    ["录入产品", "Product|item_list"],
    ["新增产品", "Product|create"], 
    ["修改产品", "Product|update"], 
    ["提交产品", "Product|commit"], 
    ["删除产品", "Product|update_destroy"], 
    ["冻结产品", "Product|freeze"], 
    ["恢复产品", "Product|recover"]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => item_list)
  end
  agent = Menu.create(:name => "我的代理商", :route_path => "/kobe/agents", :can_opt_action => "Agent|read", :is_show => true, :parent => item_manage)
  [ ["维护代理商", "Agent|list"], 
    ["新增代理商", "Agent|create"], 
    ["修改代理商", "Agent|update"], 
    ["删除代理商", "Agent|update_destroy"]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => agent)
  end
  coordinator = Menu.create(:name => "我的总协调人", :route_path => "/kobe/coordinators", :can_opt_action => "Coordinator|read", :is_show => true, :parent => item_manage)
  [ ["维护总协调人", "Coordinator|list"], 
    ["新增总协调人", "Coordinator|create"], 
    ["修改总协调人", "Coordinator|update"], 
    ["删除总协调人", "Coordinator|update_destroy"]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => coordinator)
  end
  
  audit_product = Menu.create(:name => "审核产品", :route_path => "/kobe/products/list", :can_opt_action => "Product|list", :is_show => true, :parent => item_manage)
  [["产品初审", "Product|first_audit"], ["产品终审", "Product|last_audit"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => audit_product)
  end

  Menu.create(:name => "入围产品管理", :route_path => "/kobe/products", :can_opt_action => "Product|admin", :is_show => true, :parent => item_manage)
  Menu.create(:name => "代理商管理", :route_path => "/kobe/agents", :can_opt_action => "Agent|admin", :is_show => true, :parent => item_manage)
  Menu.create(:name => "总协调人管理", :route_path => "/kobe/coordinators", :can_opt_action => "Coordinator|admin", :is_show => true, :parent => item_manage)

# ----采购计划项目管理---------------------------------------------------------------------------------
  plan_item = Menu.create(:name => "采购计划项目管理", :route_path => "/kobe/plan_items", :can_opt_action => "PlanItem|read", :is_show => true, :parent => yw)
  [ ["增加采购计划项目", "PlanItem|create"], 
    ["修改采购计划项目", "PlanItem|update"], 
    ["提交采购计划项目", "PlanItem|commit"], 
    ["删除采购计划项目", "PlanItem|update_destroy"]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => plan_item)
  end

# ----采购计划管理-------------------------------------------------------------------------------------
  plan = Menu.create(:name => "采购计划管理", :is_show => true, :parent => yw)
  Menu.create(:name => "可上报的采购计划", :route_path => "/kobe/plan_items/list", :can_opt_action => "PlanItem|list", :is_show => true, :parent => plan)
  plan_list = Menu.create(:name => "辖区内采购计划", :route_path => "/kobe/plans", :can_opt_action => "Plan|read", :is_show => true, :parent => plan)
  [ ["查看采购计划项目", "PlanItem|show"],
    ["录入采购计划", "Plan|item_list"],
    ["新增采购计划", "Plan|create"], 
    ["修改采购计划", "Plan|update"], 
    ["提交采购计划", "Plan|commit"], 
    ["删除采购计划", "Plan|update_destroy"] 
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => plan_list)
  end
  audit_plan = Menu.create(:name => "审核采购计划", :route_path => "/kobe/plans/list", :can_opt_action => "Plan|list", :is_show => true, :parent => plan)
  [["采购计划初审", "Plan|first_audit"], ["采购计划终审", "Plan|last_audit"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => audit_plan)
  end

# ----预算管理-------------------------------------------------------------------------------------
  budget = Menu.create(:name => "预算审批单", :is_show => true, :parent => yw)
  budget_list = Menu.create(:name => "辖区内预算审批单", :route_path => "/kobe/budgets", :can_opt_action => "Budget|read", :is_show => true, :parent => budget)
  [ ["新增预算审批单", "Budget|create"], 
    ["修改预算审批单", "Budget|update"], 
    ["提交预算审批单", "Budget|commit"], 
    ["删除预算审批单", "Budget|update_destroy"] 
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => budget_list)
  end
  audit_budget = Menu.create(:name => "审核预算审批单", :route_path => "/kobe/budgets/list", :can_opt_action => "Budget|list", :is_show => true, :parent => budget)
  [["预算审批单初审", "Budget|first_audit"], ["预算审批单终审", "Budget|last_audit"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => audit_budget)
  end

# ----定点采购-----------------------------------------------------------------------------------------
  ddcg = Menu.create(:name => "定点采购", :is_show => true, :parent => yw)
  ddcg_list = Menu.create(:name => "我的定点采购项目", :route_path => "/kobe/orders/ddcg_list", :can_opt_action => "Order|ddcg_list", :is_show => true, :parent => ddcg)
  [ ["查看定点采购", "Order|read"],
    ["增加定点采购", "Order|create"], 
    ["修改定点采购", "Order|update"], 
    ["提交定点采购", "Order|commit"], 
    ["删除定点采购", "Order|update_destroy"], 
    ["打印定点采购订单", "Order|print"]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => ddcg_list)
  end
  audit_ddcg = Menu.create(:name => "审核定点采购", :route_path => "/kobe/orders/audit_ddcg", :can_opt_action => "Order|audit_ddcg", :is_show => true, :parent => ddcg)
  [["定点采购初审", "Order|first_audit"], ["定点采购终审", "Order|last_audit"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => audit_ddcg)
  end

# ----日常费用报销类别---------------------------------------------------------------------------------
  daily_cost = Menu.create(:name => "日常费用报销", :is_show => true, :parent => yw)
  daily_cost_category = Menu.create(:name => "维护费用类别",:route_path => "/kobe/daily_categories", :can_opt_action => "DailyCategory|read", :is_show => true, :parent => daily_cost)
  [ ["增加费用类别", "DailyCategory|create"], 
    ["修改费用类别", "DailyCategory|update"], 
    ["删除费用类别", "DailyCategory|update_destroy"], 
    ["移动费用类别", "DailyCategory|move"]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => daily_cost_category)
  end

# ---日常费用报销--------------------------------------------------------------------------------------
  cost_index = Menu.create(:name => "日常报销清单", :route_path => "/kobe/daily_costs", :can_opt_action => "DailyCost|read", :is_show => true, :parent => daily_cost)
  [  
    ["新增日常报销", "DailyCost|create"], 
    ["修改日常报销", "DailyCost|update"], 
    ["提交日常报销", "DailyCost|commit"], 
    ["删除日常报销", "DailyCost|update_destroy"] 
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => cost_index)
  end
  audit_cost = Menu.create(:name => "审核日常报销", :route_path => "/kobe/daily_costs/list", :can_opt_action => "DailyCost|list", :is_show => true, :parent => daily_cost)
  [["日常报销初审", "DailyCost|first_audit"], ["日常报销终审", "DailyCost|last_audit"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => audit_cost)
  end

# ----车辆信息维护-------------------------------------------------------------------------------------
  fixed_asset = Menu.create(:name => "车辆信息维护", :is_show => true, :parent => yw)
  fixed_asset_list = Menu.create(:name => "车辆信息维护",:route_path => "/kobe/fixed_assets", :can_opt_action => "FixedAsset|read", :is_show => true, :parent => fixed_asset)
  [ ["增加车辆信息", "FixedAsset|create"], 
    ["修改车辆信息", "FixedAsset|update"], 
    ["删除车辆信息", "FixedAsset|update_destroy"] 
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => fixed_asset_list)
  end

# ---车辆费用报销--------------------------------------------------------------------------------------
  asset_index = Menu.create(:name => "车辆费用报销", :route_path => "/kobe/asset_projects", :can_opt_action => "AssetProject|read", :is_show => true, :parent => fixed_asset)
  [  
    ["新增车辆报销", "AssetProject|create"], 
    ["修改车辆报销", "AssetProject|update"], 
    ["提交车辆报销", "AssetProject|commit"], 
    ["删除车辆报销", "AssetProject|update_destroy"] 
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => asset_index)
  end
  audit_asset = Menu.create(:name => "审核车辆报销", :route_path => "/kobe/asset_projects/list", :can_opt_action => "AssetProject|list", :is_show => true, :parent => fixed_asset)
  [["车辆报销初审", "AssetProject|first_audit"], ["车辆报销终审", "AssetProject|last_audit"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => audit_asset)
  end

# ----单位及用户管理-----------------------------------------------------------------------------------
  dep = Menu.create(:name => "单位及用户管理", :icon => "fa-users", :is_auto => true, :is_show => true)
  dep_p = Menu.create(:name => "单位管理", :route_path => "/kobe/departments", :can_opt_action => "Department|read", :is_show => true, :is_auto => true, :parent => dep)
  [ ["增加下属单位", "Department|create", false], 
    ["修改单位信息", "Department|update", true], 
    ["上传附件", "Department|upload", true], 
    ["分配人员账号", "Department|add_user", false], 
    ["维护开户银行", "Department|bank", true], 
    ["提交", "Department|commit", true], 
    ["删除单位", "Department|update_destroy", false], 
    ["冻结单位", "Department|freeze", false], 
    ["恢复单位", "Department|recover", false], 
    ["移动单位", "Department|move", false]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :is_auto => m[2], :parent => dep_p)
  end
  
  Menu.create(:name => "单位查询", :route_path => "/kobe/departments/search", :can_opt_action => "Department|search", :is_show => true, :parent => dep)

  audit_dep = Menu.create(:name => "审核单位", :route_path => "/kobe/departments/list", :can_opt_action => "Department|list", :is_show => true, :parent => dep)
  [["单位初审", "Department|first_audit"], ["单位终审", "Department|last_audit"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => audit_dep)
  end

  user = Menu.create(:name => "用户管理", :route_path => "/kobe/users", :can_opt_action => "User|read", :is_show => true, :is_auto => true, :parent => dep)
  [ ["修改用户", "User|update", true],
    ["重置密码", "User|reset_password", false],
    ["冻结用户", "User|freeze", false],
    ["恢复用户", "User|recover", false],
    ["user_admin","User|admin", false]
  ].each do |u|
    Menu.create(:name => u[0], :can_opt_action => u[1], :is_auto => u[2], :parent => user)
  end

# ----公告管理-----------------------------------------------------------------------------------------
  article = Menu.find_or_create_by(:name => "公告管理", :icon => "fa-tag", :is_show => true)

  article_list = Menu.find_or_initialize_by(:name => "公告列表", :route_path => "/kobe/articles", :can_opt_action => "Article|read", :is_show => true)
  article_list.parent = article
  article_list.save
  [ ["增加公告", "Article|create"], 
    ["修改公告", "Article|update"], 
    ["删除公告", "Article|update_destroy"],
    ["提交公告", "Article|commit"]
  ].each do |m|
    ac = Menu.find_or_initialize_by(:name => m[0], :can_opt_action => m[1])
    ac.parent = article_list
    ac.save
  end

  audit_article = Menu.find_or_initialize_by(:name => "审核公告", :route_path => "/kobe/articles/list", :can_opt_action => "Article|list", :is_show => true)
  audit_article.parent = article
  audit_article.save
  [["公告初审", "Article|first_audit"], ["公告终审", "Article|last_audit"]].each do |m|
    a = Menu.find_or_initialize_by(:name => m[0], :can_opt_action => m[1])
    a.parent = audit_article
    a.save
  end

  article_catalog = Menu.find_or_initialize_by(:name => "公告目录管理", :route_path => "/kobe/article_catalogs", :can_opt_action => "ArticleCatalog|read", :is_show => true)
  article_catalog.parent = article
  article_catalog.save
  [ ["增加公告目录", "ArticleCatalog|create"], 
    ["修改公告目录", "ArticleCatalog|update"], 
    ["删除公告目录", "ArticleCatalog|update_destroy"],
    ["移动公告目录", "ArticleCatalog|move"]
  ].each do |m|
    ac = Menu.find_or_initialize_by(:name => m[0], :can_opt_action => m[1])
    ac.parent = article_catalog
    ac.save
  end

# ----数据统计与分析-----------------------------------------------------------------------------------
  tongji = Menu.find_or_create_by(:name => "数据统计与分析", :icon => "fa-bar-chart-o", :is_show => true)

  all_tj = Menu.find_or_initialize_by(:name => "整体采购统计", :route_path => "/kobe/tongji", :can_opt_action => "Tongji|read", :is_show => true)
  all_tj.parent = tongji
  all_tj.save

  item_dep_tj = Menu.find_or_initialize_by(:name => "入围供应商销量统计", :route_path => "/kobe/tongji/item_dep_sales", :can_opt_action => "Tongji|read", :is_show => true)
  item_dep_tj.parent = tongji
  item_dep_tj.save


# ----系统设置-----------------------------------------------------------------------------------------
  setting = Menu.find_or_create_by(:name => "系统设置", :icon => "fa-cogs", :is_show => true)

  menu = Menu.create(:name => "菜单管理", :route_path => "/kobe/menus", :can_opt_action => "Menu|read", :is_show => true, :parent => setting)
  [ ["增加菜单", "Menu|create"], 
    ["修改菜单", "Menu|update"], 
    ["删除菜单", "Menu|update_destroy"], 
    ["移动菜单", "Menu|move"]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => menu)
  end

  contract_template = Menu.create(:name => "合同模板", :route_path => "/kobe/contract_templates", :can_opt_action => "ContractTemplate|read", :is_show => true, :parent => setting)
  [ ["增加合同", "ContractTemplate|create"], 
    ["修改合同", "ContractTemplate|update"], 
    ["删除合同", "ContractTemplate|update_destroy"]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => contract_template)
  end

  to_do_list = Menu.create(:name => "待办事项", :route_path => "/kobe/to_do_lists", :can_opt_action => "ToDoList|read", :is_show => true, :parent => setting)
  [ ["增加待办事项", "ToDoList|create"], 
    ["修改待办事项", "ToDoList|update"], 
    ["删除待办事项", "ToDoList|update_destroy"]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => to_do_list)
  end

  rule = Menu.create(:name => "流程定制", :route_path => "/kobe/rules", :can_opt_action => "Rule|read", :is_show => true, :parent => setting)
  [ ["增加", "Rule|create"], 
    ["修改", "Rule|update"], 
    ["删除", "Rule|update_destroy"], 
    ["维护审核理由", "Rule|audit_reason"]
  ].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => rule)
  end

 end

# ----网上竞价-----------------------------------------------------------------------------------------
  yw = Menu.find_or_create_by(:name => "业务管理", :icon => "fa-tasks", :is_auto => true, :is_show => true)
  ra_project = Menu.find_or_initialize_by(:name => "网上竞价", :is_show => true)
  ra_project.parent = yw
  ra_project.save

  wsjj_list = Menu.find_or_initialize_by(:name => "网上竞价列表", :route_path => "/kobe/bid_projects", :can_opt_action => "BidProject|read", :is_show => true)
  wsjj_list.parent = ra_project
  wsjj_list.save
  [ ["增加网上竞价", "BidProject|create"], 
    ["修改网上竞价", "BidProject|update"], 
    ["删除网上竞价", "BidProject|update_destroy"],
    ["提交网上竞价", "BidProject|commit"]
  ].each do |m|
    ac = Menu.find_or_initialize_by(:name => m[0], :can_opt_action => m[1])
    ac.parent = wsjj_list
    ac.save
  end

  audit_wsjj = Menu.find_or_initialize_by(:name => "审核网上竞价", :route_path => "/kobe/bid_projects/list", :can_opt_action => "BidProject|list", :is_show => true)
  audit_wsjj.parent = ra_project
  audit_wsjj.save
  [["网上竞价初审", "BidProject|first_audit"], ["网上竞价终审", "BidProject|last_audit"]].each do |m|
    a = Menu.find_or_initialize_by(:name => m[0], :can_opt_action => m[1])
    a.parent = audit_wsjj
    a.save
  end

  # [ ["我的项目", "BidProject|read", "/kobe/bid_projects", true], 
  #   ["新建竞价", "BidProject|create", "/kobe/bid_projects/new", false],
  #   ["修改竞价", "BidProject|update", "/kobe/bid_projects/edit", false],
  #   ["删除竞价", "BidProject|update_destroy", "/kobe/bid_projects/update_destroy", false],
  #   ["提交审核", "BidProject|commit", "", false],
  #   ["审核竞价", "BidProject|lsit", "/kobe/bid_projects/list", true]
  # ].each_with_index do |m, i|
  #   m = Menu.find_or_initialize_by(:name => m[0], :can_opt_action => m[1], route_path: m[2], is_show: m[3])
  #   next if m.id.present?
  #   m.parent = ra_project
  #   m.save
  # end


if Category.first.blank?
  # a = Category.create(:name => "办公物资", :status => 1) 
  # b = Category.create(:name => "粮机物资", :status => 1) 
  # ["计算机","打印机","复印机","服务器"].each do |option|
  #   Category.create(:name => option, :status => 1, :parent => a)
  # end
  # ["输送机","清理筛"].each do |option|
  #   Category.create(:name => option, :status => 1, :parent => b)
  # end
  file = File.open("#{Rails.root}/db/sql/categories.sql")
  file.each{ |line|
    ActiveRecord::Base.connection.execute(line)
  }
  file.close
end

if Bank.first.blank?
  # source = File.new("#{Rails.root}/db/sql/banks.sql", "r")
  # line = source.gets
  file = File.open("#{Rails.root}/db/sql/banks.sql")
  file.each{ |line|
    ActiveRecord::Base.connection.execute(line)
  }
  file.close
end
