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

# if Department.first.blank?
#   [["执行机构","1"],["采购单位", "1"], ["供应商", "1"], ["监管机构", "1"], ["评审专家", "1"]].each do |option|
#     Department.create(name: option[0], status: option[1])
#   end
# end

if Menu.first.blank?
  manage_user_type = '1'
  purchaser_user_type = '2'
  supplier_user_type = '3'
  mp_ut = '1,2'
  ms_ut = '1,3'
  all_ut = '1,2,3'

  yw = Menu.find_or_create_by(name: "业务管理", icon: "fa-tasks", is_auto: true, is_show: true, user_type: all_ut)
# ----订单中心-----------------------------------------------------------------------------------------
  ddzc = Menu.find_or_initialize_by(name: "订单中心", route_path: "/kobe/orders", can_opt_action: "Order|read", is_show: true, user_type: all_ut)
  ddzc.parent = yw
  ddzc.save
  
# ----品目管理-----------------------------------------------------------------------------------------
  category = Menu.find_or_initialize_by(name: "品目管理", route_path: "/kobe/categories", can_opt_action: "Category|read", is_show: true, user_type: manage_user_type)
  category.parent = yw
  category.save

  [ ["增加品目", "Category|create"], 
    ["修改品目", "Category|update"], 
    ["删除品目", "Category|update_destroy"],
    ["冻结品目", "Category|freeze"],
    ["恢复品目", "Category|recover"], 
    ["移动品目", "Category|move"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = category
    tmp.save
  end

# ----入围项目管理-------------------------------------------------------------------------------------
  item = Menu.find_or_initialize_by(name: "入围项目管理", route_path: "/kobe/items", can_opt_action: "Item|read", is_show: true, user_type: manage_user_type)
  item.parent = yw
  item.save

  [ ["增加项目", "Item|create"], 
    ["修改项目", "Item|update"], 
    ["提交项目", "Item|commit"], 
    ["停止项目", "Item|pause"], 
    ["恢复项目", "Item|recover"], 
    ["删除项目", "Item|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = item
    tmp.save
  end

# ----入围产品管理-------------------------------------------------------------------------------------
  item_manage = Menu.find_or_initialize_by(name: "入围产品管理", is_show: true, user_type: ms_ut)
  item_manage.parent = yw
  item_manage.save

  my_item_list = Menu.find_or_initialize_by(name: "我的入围项目", route_path: "/kobe/items/list", can_opt_action: "Item|list", is_show: true, user_type: supplier_user_type)
  my_item_list.parent = item_manage
  my_item_list.save

  item_list = Menu.find_or_initialize_by(name: "我的入围产品", route_path: "/kobe/products", can_opt_action: "Product|read", is_show: true, user_type: supplier_user_type)
  item_list.parent = item_manage
  item_list.save

  [ ["查看项目", "Item|show"],
    ["录入产品", "Product|item_list"],
    ["新增产品", "Product|create"], 
    ["修改产品", "Product|update"], 
    ["提交产品", "Product|commit"], 
    ["删除产品", "Product|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: supplier_user_type)
    tmp.parent = item_list
    tmp.save
  end
  
  agent = Menu.find_or_initialize_by(name: "我的代理商", route_path: "/kobe/agents", can_opt_action: "Agent|read", is_show: true, user_type: supplier_user_type)
  agent.parent = item_manage
  agent.save

  [ ["维护代理商", "Agent|list"], 
    ["新增代理商", "Agent|create"], 
    ["修改代理商", "Agent|update"], 
    ["删除代理商", "Agent|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: supplier_user_type)
    tmp.parent = agent
    tmp.save
  end

  coordinator = Menu.find_or_initialize_by(name: "我的总协调人", route_path: "/kobe/coordinators", can_opt_action: "Coordinator|read", is_show: true, user_type: supplier_user_type)
  coordinator.parent = item_manage
  coordinator.save

  [ ["维护总协调人", "Coordinator|list"], 
    ["新增总协调人", "Coordinator|create"], 
    ["修改总协调人", "Coordinator|update"], 
    ["删除总协调人", "Coordinator|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: supplier_user_type)
    tmp.parent = coordinator
    tmp.save
  end
  
  audit_product = Menu.find_or_initialize_by(name: "审核产品", route_path: "/kobe/products/list", can_opt_action: "Product|list", is_show: true, user_type: manage_user_type)
  audit_product.parent = item_manage
  audit_product.save

  [["产品初审", "Product|first_audit"], ["产品终审", "Product|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = audit_product
    tmp.save
  end

  product_manage = Menu.find_or_initialize_by(name: "入围产品管理", route_path: "/kobe/products", can_opt_action: "Product|admin", is_show: true, user_type: manage_user_type)
  product_manage.parent = item_manage
  product_manage.save

  [ ["下架产品", "Product|freeze"], 
    ["恢复产品", "Product|recover"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = product_manage
    tmp.save
  end

  agent_manage = Menu.find_or_initialize_by(name: "代理商管理", route_path: "/kobe/agents", can_opt_action: "Agent|admin", is_show: true, user_type: manage_user_type)
  agent_manage.parent = item_manage
  agent_manage.save

  coordinator_manage = Menu.find_or_initialize_by(name: "总协调人管理", route_path: "/kobe/coordinators", can_opt_action: "Coordinator|admin", is_show: true, user_type: manage_user_type)
  coordinator_manage.parent = item_manage
  coordinator_manage.save

# ----采购计划项目管理---------------------------------------------------------------------------------
  plan_item = Menu.find_or_initialize_by(name: "采购计划项目管理", route_path: "/kobe/plan_items", can_opt_action: "PlanItem|read", is_show: true, user_type: manage_user_type)
  plan_item.parent = yw
  plan_item.save

  [ ["增加采购计划项目", "PlanItem|create"], 
    ["修改采购计划项目", "PlanItem|update"], 
    ["提交采购计划项目", "PlanItem|commit"], 
    ["删除采购计划项目", "PlanItem|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = plan_item
    tmp.save
  end

# ----采购计划管理-------------------------------------------------------------------------------------
  plan = Menu.find_or_initialize_by(name: "采购计划管理", is_show: true, user_type: mp_ut)
  plan.parent = yw
  plan.save

  plan_items_list = Menu.find_or_initialize_by(name: "可上报的采购计划", route_path: "/kobe/plan_items/list", can_opt_action: "PlanItem|list", is_show: true, user_type: mp_ut)
  plan_items_list.parent = plan
  plan_items_list.save

  plan_list = Menu.find_or_initialize_by(name: "辖区内采购计划", route_path: "/kobe/plans", can_opt_action: "Plan|read", is_show: true, user_type: mp_ut)
  plan_list.parent = plan
  plan_list.save

  [ ["查看采购计划项目", "PlanItem|show"],
    ["录入采购计划", "Plan|item_list"],
    ["新增采购计划", "Plan|create"], 
    ["修改采购计划", "Plan|update"], 
    ["提交采购计划", "Plan|commit"], 
    ["删除采购计划", "Plan|update_destroy"] 
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: mp_ut)
    tmp.parent = plan_list
    tmp.save
  end

  audit_plan = Menu.find_or_initialize_by(name: "审核采购计划", route_path: "/kobe/plans/list", can_opt_action: "Plan|list", is_show: true, user_type: mp_ut)
  audit_plan.parent = plan
  audit_plan.save

  [["采购计划初审", "Plan|first_audit"], ["采购计划终审", "Plan|last_audit"]].each do |m|
    tmp =Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: mp_ut)
    tmp.parent = audit_plan
    tmp.save
  end

# ----预算管理-------------------------------------------------------------------------------------
  budget = Menu.find_or_initialize_by(name: "预算审批单", is_show: true, user_type: mp_ut)
  budget.parent = yw
  budget.save

  budget_list = Menu.find_or_initialize_by(name: "辖区内预算审批单", route_path: "/kobe/budgets", can_opt_action: "Budget|read", is_show: true, user_type: mp_ut)
  budget_list.parent = budget
  budget_list.save

  [ ["新增预算审批单", "Budget|create"], 
    ["修改预算审批单", "Budget|update"], 
    ["提交预算审批单", "Budget|commit"], 
    ["删除预算审批单", "Budget|update_destroy"] 
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: mp_ut)
    tmp.parent = budget_list
    tmp.save
  end

  audit_budget = Menu.find_or_initialize_by(name: "审核预算审批单", route_path: "/kobe/budgets/list", can_opt_action: "Budget|list", is_show: true, user_type: mp_ut)
  audit_budget.parent = budget
  audit_budget.save

  [["预算审批单初审", "Budget|first_audit"], ["预算审批单终审", "Budget|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: mp_ut)
    tmp.parent = audit_budget
    tmp.save
  end

# ----定点采购-----------------------------------------------------------------------------------------
  ddcg = Menu.find_or_initialize_by(name: "定点采购", is_show: true, user_type: mp_ut)
  ddcg.parent = yw
  ddcg.save

  ddcg_list = Menu.find_or_initialize_by(name: "我的定点采购项目", route_path: "/kobe/orders/ddcg_list", can_opt_action: "Order|ddcg_list", is_show: true, user_type: mp_ut)
  ddcg_list.parent = ddcg
  ddcg_list.save

  [ ["查看定点采购", "Order|read"],
    ["增加定点采购", "Order|create"], 
    ["修改定点采购", "Order|update"], 
    ["提交定点采购", "Order|commit"], 
    ["删除定点采购", "Order|update_destroy"], 
    ["打印定点采购订单", "Order|print"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: mp_ut)
    tmp.parent = ddcg_list
    tmp.save
  end

  audit_ddcg = Menu.find_or_initialize_by(name: "审核定点采购", route_path: "/kobe/orders/audit_ddcg", can_opt_action: "Order|audit_ddcg", is_show: true, user_type: mp_ut)
  audit_ddcg.parent = ddcg
  audit_ddcg.save


  [["定点采购初审", "Order|first_audit"], ["定点采购终审", "Order|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: mp_ut)
    tmp.parent = audit_ddcg
    tmp.save
  end

# ----网上竞价-----------------------------------------------------------------------------------------
  ra_project = Menu.find_or_initialize_by(name: "网上竞价", is_show: true, user_type: all_ut)
  ra_project.parent = yw
  ra_project.save

  wsjj_list = Menu.find_or_initialize_by(name: "网上竞价列表", route_path: "/kobe/bid_projects", can_opt_action: "BidProject|read", is_show: true, user_type: mp_ut)
  wsjj_list.parent = ra_project
  wsjj_list.save

  [ ["增加网上竞价", "BidProject|create"], 
    ["修改网上竞价", "BidProject|update"], 
    ["删除网上竞价", "BidProject|update_destroy"],
    ["提交网上竞价", "BidProject|commit"]
  ].each do |m|
    ac = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: mp_ut)
    ac.parent = wsjj_list
    ac.save
  end

  audit_wsjj = Menu.find_or_initialize_by(name: "审核网上竞价", route_path: "/kobe/bid_projects/list", can_opt_action: "BidProject|list", is_show: true, user_type: mp_ut)
  audit_wsjj.parent = ra_project
  audit_wsjj.save

  [["网上竞价初审", "BidProject|first_audit"], ["网上竞价终审", "BidProject|last_audit"]].each do |m|
    a = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: mp_ut)
    a.parent = audit_wsjj
    a.save
  end

# ----日常费用报销类别---------------------------------------------------------------------------------
  daily_cost = Menu.find_or_initialize_by(name: "日常费用报销", is_show: true, user_type: manage_user_type)
  daily_cost.parent = yw
  daily_cost.save

  daily_cost_category = Menu.find_or_initialize_by(name: "维护费用类别",route_path: "/kobe/daily_categories", can_opt_action: "DailyCategory|read", is_show: true, user_type: manage_user_type)
  daily_cost_category.parent = daily_cost
  daily_cost_category.save

  [ ["增加费用类别", "DailyCategory|create"], 
    ["修改费用类别", "DailyCategory|update"], 
    ["删除费用类别", "DailyCategory|update_destroy"], 
    ["移动费用类别", "DailyCategory|move"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = daily_cost_category
    tmp.save
  end

# ---日常费用报销--------------------------------------------------------------------------------------
  cost_index = Menu.find_or_initialize_by(name: "日常报销清单", route_path: "/kobe/daily_costs", can_opt_action: "DailyCost|read", is_show: true, user_type: manage_user_type)
  cost_index.parent = daily_cost
  cost_index.save

  [  
    ["新增日常报销", "DailyCost|create"], 
    ["修改日常报销", "DailyCost|update"], 
    ["提交日常报销", "DailyCost|commit"], 
    ["删除日常报销", "DailyCost|update_destroy"] 
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = cost_index
    tmp.save
  end

  audit_cost = Menu.find_or_initialize_by(name: "审核日常报销", route_path: "/kobe/daily_costs/list", can_opt_action: "DailyCost|list", is_show: true, user_type: manage_user_type)
  audit_cost.parent = daily_cost
  audit_cost.save

  [["日常报销初审", "DailyCost|first_audit"], ["日常报销终审", "DailyCost|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = audit_cost
    tmp.save
  end

# ----车辆信息维护-------------------------------------------------------------------------------------
  fixed_asset = Menu.find_or_initialize_by(name: "车辆信息维护", is_show: true, user_type: manage_user_type)
  fixed_asset.parent = yw
  fixed_asset.save

  fixed_asset_list = Menu.find_or_initialize_by(name: "车辆信息维护",route_path: "/kobe/fixed_assets", can_opt_action: "FixedAsset|read", is_show: true, user_type: manage_user_type)
  fixed_asset_list.parent = fixed_asset
  fixed_asset_list.save

  [ ["增加车辆信息", "FixedAsset|create"], 
    ["修改车辆信息", "FixedAsset|update"], 
    ["删除车辆信息", "FixedAsset|update_destroy"] 
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = fixed_asset_list
    tmp.save
  end

# ---车辆费用报销--------------------------------------------------------------------------------------
  asset_index = Menu.find_or_initialize_by(name: "车辆费用报销", route_path: "/kobe/asset_projects", can_opt_action: "AssetProject|read", is_show: true, user_type: manage_user_type)
  asset_index.parent = fixed_asset
  asset_index.save

  [  
    ["新增车辆报销", "AssetProject|create"], 
    ["修改车辆报销", "AssetProject|update"], 
    ["提交车辆报销", "AssetProject|commit"], 
    ["删除车辆报销", "AssetProject|update_destroy"] 
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = asset_index
    tmp.save
  end

  audit_asset = Menu.find_or_initialize_by(name: "审核车辆报销", route_path: "/kobe/asset_projects/list", can_opt_action: "AssetProject|list", is_show: true, user_type: manage_user_type)
  audit_asset.parent = fixed_asset
  audit_asset.save

  [["车辆报销初审", "AssetProject|first_audit"], ["车辆报销终审", "AssetProject|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = audit_asset
    tmp.save
  end

# ----单位及用户管理-----------------------------------------------------------------------------------
  dep = Menu.find_or_create_by(name: "单位及用户管理", icon: "fa-users", is_auto: true, is_show: true, user_type: all_ut)

  dep_p = Menu.find_or_initialize_by(name: "单位管理", route_path: "/kobe/departments", can_opt_action: "Department|read", is_show: true, is_auto: true, user_type: all_ut)
  dep_p.parent = dep
  dep_p.save

  [ ["增加下属单位", "Department|create", false, all_ut], 
    ["修改单位信息", "Department|update", true, all_ut], 
    ["上传附件", "Department|upload", true, all_ut], 
    ["分配人员账号", "Department|add_user", false, all_ut], 
    ["维护开户银行", "Department|bank", true, all_ut], 
    ["提交", "Department|commit", true, all_ut], 
    ["删除单位", "Department|update_destroy", false, manage_user_type], 
    ["冻结单位", "Department|freeze", false, manage_user_type], 
    ["恢复单位", "Department|recover", false, manage_user_type], 
    ["移动单位", "Department|move", false, manage_user_type]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], is_auto: m[2], user_type: m[3])
    tmp.parent = dep_p
    tmp.save
  end
  
  dep_list = Menu.find_or_initialize_by(name: "单位查询", route_path: "/kobe/departments/search", can_opt_action: "Department|search", is_show: true, user_type: manage_user_type)
  dep_list.parent = dep
  dep_list.save

  audit_dep = Menu.find_or_initialize_by(name: "审核单位", route_path: "/kobe/departments/list", can_opt_action: "Department|list", is_show: true, user_type: manage_user_type)
  audit_dep.parent = dep
  audit_dep.save

  [["单位初审", "Department|first_audit"], ["单位终审", "Department|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = audit_dep
    tmp.save
  end

  user = Menu.find_or_initialize_by(name: "用户管理", route_path: "/kobe/users", can_opt_action: "User|read", is_show: true, is_auto: true, user_type: all_ut)
  user.parent = dep
  user.save

  [ ["修改用户", "User|update", true],
    ["重置密码", "User|reset_password", false],
    ["冻结用户", "User|freeze", false],
    ["恢复用户", "User|recover", false],
    ["user_admin","User|admin", false]
  ].each do |u|
    tmp = Menu.find_or_initialize_by(name: u[0], can_opt_action: u[1], is_auto: u[2], user_type: all_ut)
    tmp.parent = user
    tmp.save
  end

# ----公告管理-----------------------------------------------------------------------------------------
  article = Menu.find_or_create_by(name: "公告管理", icon: "fa-tag", is_show: true, user_type: manage_user_type)

  article_list = Menu.find_or_initialize_by(name: "公告列表", route_path: "/kobe/articles", can_opt_action: "Article|read", is_show: true, user_type: manage_user_type)
  article_list.parent = article
  article_list.save

  [ ["增加公告", "Article|create"], 
    ["修改公告", "Article|update"], 
    ["删除公告", "Article|update_destroy"],
    ["提交公告", "Article|commit"]
  ].each do |m|
    ac = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    ac.parent = article_list
    ac.save
  end

  audit_article = Menu.find_or_initialize_by(name: "审核公告", route_path: "/kobe/articles/list", can_opt_action: "Article|list", is_show: true, user_type: manage_user_type)
  audit_article.parent = article
  audit_article.save

  [["公告初审", "Article|first_audit"], ["公告终审", "Article|last_audit"]].each do |m|
    a = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    a.parent = audit_article
    a.save
  end

  article_catalog = Menu.find_or_initialize_by(name: "公告目录管理", route_path: "/kobe/article_catalogs", can_opt_action: "ArticleCatalog|read", is_show: true, user_type: manage_user_type)
  article_catalog.parent = article
  article_catalog.save

  [ ["增加公告目录", "ArticleCatalog|create"], 
    ["修改公告目录", "ArticleCatalog|update"], 
    ["删除公告目录", "ArticleCatalog|update_destroy"],
    ["移动公告目录", "ArticleCatalog|move"]
  ].each do |m|
    ac = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    ac.parent = article_catalog
    ac.save
  end

# ----政策法规、相关下载、常见问题、意见建议-----------------------------------------------------------
  faq_list = Menu.find_or_initialize_by(name: "常见问题列表", route_path: "/kobe/faqs", can_opt_action: "Faq|read", is_show: true, user_type: manage_user_type)
  faq_list.parent = article
  faq_list.save

  [ ["增加常见问题", "Faq|create", all_ut], 
    ["修改常见问题", "Faq|update", manage_user_type], 
    ["删除常见问题", "Faq|update_destroy", manage_user_type],
    ["提交常见问题", "Faq|commit", manage_user_type],
    ["回复意见建议", "Faq|reply", manage_user_type]
  ].each do |m|
    ac = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: m[2])
    ac.parent = faq_list
    ac.save
  end

# ----数据统计与分析-----------------------------------------------------------------------------------
  tongji = Menu.find_or_create_by(name: "数据统计与分析", icon: "fa-bar-chart-o", is_show: true, user_type: mp_ut)

  all_tj = Menu.find_or_initialize_by(name: "整体采购统计", route_path: "/kobe/tongji", can_opt_action: "Tongji|read", is_show: true, user_type: mp_ut)
  all_tj.parent = tongji
  all_tj.save

  item_dep_tj = Menu.find_or_initialize_by(name: "入围供应商销量统计", route_path: "/kobe/tongji/item_dep_sales", can_opt_action: "Tongji|read", is_show: true, user_type: manage_user_type)
  item_dep_tj.parent = tongji
  item_dep_tj.save


# ----系统设置-----------------------------------------------------------------------------------------
  setting = Menu.find_or_create_by(name: "系统设置", icon: "fa-cogs", is_show: true, user_type: manage_user_type)

  menu = Menu.find_or_initialize_by(name: "菜单管理", route_path: "/kobe/menus", can_opt_action: "Menu|read", is_show: true, user_type: manage_user_type)
  menu.parent = setting
  menu.save

  [ ["增加菜单", "Menu|create"], 
    ["修改菜单", "Menu|update"], 
    ["删除菜单", "Menu|update_destroy"], 
    ["移动菜单", "Menu|move"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = menu
    tmp.save
  end

  contract_template = Menu.find_or_initialize_by(name: "合同模板", route_path: "/kobe/contract_templates", can_opt_action: "ContractTemplate|read", is_show: true, user_type: manage_user_type)
  contract_template.parent = setting
  contract_template.save

  [ ["增加合同", "ContractTemplate|create"], 
    ["修改合同", "ContractTemplate|update"], 
    ["删除合同", "ContractTemplate|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = contract_template
    tmp.save
  end

  to_do_list = Menu.find_or_initialize_by(name: "待办事项", route_path: "/kobe/to_do_lists", can_opt_action: "ToDoList|read", is_show: true, user_type: manage_user_type)
  to_do_list.parent = setting
  to_do_list.save

  [ ["增加待办事项", "ToDoList|create"], 
    ["修改待办事项", "ToDoList|update"], 
    ["删除待办事项", "ToDoList|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = to_do_list
    tmp.save
  end

  rule = Menu.find_or_initialize_by(name: "流程定制", route_path: "/kobe/rules", can_opt_action: "Rule|read", is_show: true, user_type: manage_user_type)
  rule.parent = setting
  rule.save

  [ ["增加", "Rule|create"], 
    ["修改", "Rule|update"], 
    ["删除", "Rule|update_destroy"], 
    ["维护审核理由", "Rule|audit_reason"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = rule
    tmp.save
  end

 end

# if Category.first.blank?
  # a = Category.create(name: "办公物资", :status => 1) 
  # b = Category.create(name: "粮机物资", :status => 1) 
  # ["计算机","打印机","复印机","服务器"].each do |option|
  #   Category.create(name: option, :status => 1, :parent => a)
  # end
  # ["输送机","清理筛"].each do |option|
  #   Category.create(name: option, :status => 1, :parent => b)
  # end
#   file = File.open("#{Rails.root}/db/sql/categories.sql")
#   file.each{ |line|
#     ActiveRecord::Base.connection.execute(line)
#   }
#   file.close
# end

if Bank.first.blank?
  # source = File.new("#{Rails.root}/db/sql/banks.sql", "r")
  # line = source.gets
  file = File.open("#{Rails.root}/db/sql/banks.sql")
  file.each{ |line|
    ActiveRecord::Base.connection.execute(line)
  }
  file.close
end

if ToDoList.first.blank?
  [ ["审核注册供应商", "/kobe/departments/list", "/kobe/departments/$$obj_id$$/audit"], 
    ["审核采购计划", "/kobe/plans/list", "/kobe/plans/$$obj_id$$/audit"], 
    ["审核网上竞价需求", "/kobe/bid_projects/list", "/kobe/bid_projects/$$obj_id$$/audit"], 
    ["审核网上竞价结果", "/kobe/bid_projects/list", "/kobe/bid_projects/$$obj_id$$/audit"], 
    ["审核公告", "/kobe/articles/list", "/kobe/articles/$$obj_id$$/audit"], 
    ["审核产品", "/kobe/products/list", "/kobe/products/$$obj_id$$/audit"], 
    ["审核预算审批单", "/kobe/budgets/list", "/kobe/budgets/$$obj_id$$/audit"], 
    ["审核定点采购项目", "/kobe/orders/audit_ddcg", "/kobe/orders/$$obj_id$$/audit"], 
    ["审核协议供货项目", "/kobe/orders/audit_xygh", "/kobe/orders/$$obj_id$$/audit"], 
    ["卖方确认", "/kobe/orders/list", "/kobe/orders/$$obj_id$$/audit"], 
    ["买方确认", "/kobe/orders/list", "/kobe/orders/$$obj_id$$/audit"],
    ["个人采购", "/kobe/orders/list", "/kobe/orders/$$obj_id$$/audit"] 
  ].each do |m|
    ToDoList.find_or_create_by(name: m[0], list_url: m[1], audit_url: m[2])
  end
end