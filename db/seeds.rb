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
  audit_user_type = Dictionary.audit_user_type

  yw = Menu.find_or_create_by(name: "业务管理", icon: "fa-tasks", is_show: true, user_type: all_ut)
# ----订单中心-----------------------------------------------------------------------------------------
  ddzc = Menu.find_or_initialize_by(name: "订单中心", route_path: "/kobe/orders", can_opt_action: "Order|read", is_show: true, user_type: mp_ut)
  ddzc.parent = yw
  ddzc.save

  [
    ["查看订单", "Order|show", "/kobe/orders/show"],
    ["修改订单", "Order|update", "/kobe/orders/edit"],
    ["提交订单", "Order|commit"],
    ["删除订单", "Order|update_destroy"],
    ["打印订单", "Order|print_order"],
    ["录入发票", "Order|invoice_number"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: mp_ut)
    tmp.parent = ddzc
    tmp.save
  end

  audit_order = Menu.find_or_initialize_by(name: "审核订单列表", route_path: "/kobe/orders/list", user_type: audit_user_type)
  audit_order.parent = ddzc
  audit_order.save

  audit_order_obj = Menu.find_or_initialize_by(name: "订单审核", route_path: "/kobe/orders/audit", user_type: audit_user_type)
  audit_order_obj.parent = audit_order
  audit_order_obj.save

  seller_ddzc = Menu.find_or_initialize_by(name: "我的销售订单", route_path: "/kobe/orders/seller_list", can_opt_action: "Order|read", is_show: true, user_type: supplier_user_type)
  seller_ddzc.parent = yw
  seller_ddzc.save

  [
    ["查看订单", "Order|show", "/kobe/orders/show"],
    ["打印凭证", "Order|print_order"],
    ["录入发票", "Order|invoice_number"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: supplier_user_type)
    tmp.parent = seller_ddzc
    tmp.save
  end

# ----入围产品管理-----------------------------------------------------------------------------------
  item_manage = Menu.find_or_initialize_by(name: "入围产品管理", is_show: true, user_type: ms_ut)
  item_manage.parent = yw
  item_manage.save

  my_item_list = Menu.find_or_initialize_by(name: "我的入围项目", route_path: "/kobe/items/list", can_opt_action: "Item|list", is_show: true, user_type: supplier_user_type)
  my_item_list.parent = item_manage
  my_item_list.save

  [ ["查看项目", "Item|show", "/kobe/items/show"],
    ["录入产品", "Product|item_list", "/kobe/products/item_list"],
    ["维护代理商", "Agent|list", "/kobe/agents/list"],
    ["维护总协调人", "Coordinator|list", "/kobe/coordinators/list"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: supplier_user_type)
    tmp.parent = my_item_list
    tmp.save
  end

  item_list = Menu.find_or_initialize_by(name: "我的入围产品", route_path: "/kobe/products", can_opt_action: "Product|read", is_show: true, user_type: supplier_user_type)
  item_list.parent = item_manage
  item_list.save

  [ ["查看产品", "Product|show", "/kobe/products/show"],
    ["新增产品", "Product|create", "/kobe/products/new"],
    ["修改产品", "Product|update", "/kobe/products/edit"],
    ["提交产品", "Product|commit"],
    ["删除产品", "Product|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: supplier_user_type)
    tmp.parent = item_list
    tmp.save
  end

  agent = Menu.find_or_initialize_by(name: "我的代理商", route_path: "/kobe/agents", can_opt_action: "Agent|read", is_show: true, user_type: supplier_user_type)
  agent.parent = item_manage
  agent.save

  [ ["查看代理商", "Agent|show", "/kobe/agents/show"],
    ["新增代理商", "Agent|create", "/kobe/agents/new"],
    ["修改代理商", "Agent|update", "/kobe/agents/edit"],
    ["删除代理商", "Agent|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: supplier_user_type)
    tmp.parent = agent
    tmp.save
  end

  coordinator = Menu.find_or_initialize_by(name: "总协调人信息", route_path: "/kobe/coordinators", can_opt_action: "Coordinator|read", is_show: true, user_type: supplier_user_type)
  coordinator.parent = item_manage
  coordinator.save

  [ ["查看总协调人", "Coordinator|show", "/kobe/coordinators/show"],
    ["新增总协调人", "Coordinator|create", "/kobe/coordinators/new"],
    ["修改总协调人", "Coordinator|update", "/kobe/coordinators/edit"],
    ["删除总协调人", "Coordinator|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: supplier_user_type)
    tmp.parent = coordinator
    tmp.save
  end

  audit_product = Menu.find_or_initialize_by(name: "等待审核的产品", route_path: "/kobe/products/list", can_opt_action: "Product|list", is_show: true, user_type: manage_user_type)
  audit_product.parent = item_manage
  audit_product.save

  audit_product_obj = Menu.find_or_initialize_by(name: "产品审核", route_path: "/kobe/products/audit", user_type: manage_user_type)
  audit_product_obj.parent = audit_product
  audit_product_obj.save

  [["产品初审", "Product|first_audit"], ["产品终审", "Product|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = audit_product_obj
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

# ----预算管理-------------------------------------------------------------------------------------
  # budget = Menu.find_or_initialize_by(name: "预算审批单", is_show: true, user_type: mp_ut)
  # budget.parent = yw
  # budget.save

  # my_budget_list = Menu.find_or_initialize_by(name: "我的预算审批单", route_path: "/kobe/budgets?t=my", can_opt_action: "Budget|read", is_show: true, user_type: mp_ut)
  # my_budget_list.parent = budget
  # my_budget_list.save

  # [ ["查看预算审批单", "Budget|show", "/kobe/budgets/show"],
  #   ["新增预算审批单", "Budget|create", "/kobe/budgets/new"],
  #   ["修改预算审批单", "Budget|update", "/kobe/budgets/edit"],
  #   ["提交预算审批单", "Budget|commit"],
  #   ["删除预算审批单", "Budget|update_destroy"]
  # ].each do |m|
  #   tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: mp_ut)
  #   tmp.parent = my_budget_list
  #   tmp.save
  # end

  # budget_list = Menu.find_or_initialize_by(name: "辖区内预算审批单", route_path: "/kobe/budgets", can_opt_action: "Budget|read", is_show: true, user_type: mp_ut)
  # budget_list.parent = budget
  # budget_list.save

  # audit_budget = Menu.find_or_initialize_by(name: "等待审核的预算审批单", route_path: "/kobe/budgets/list", can_opt_action: "Budget|list", is_show: true, user_type: audit_user_type)
  # audit_budget.parent = budget
  # audit_budget.save

  # audit_budget_obj = Menu.find_or_initialize_by(name: "预算审批单审核", route_path: "/kobe/budgets/audit", user_type: audit_user_type)
  # audit_budget_obj.parent = audit_budget
  # audit_budget_obj.save

  # [["预算审批单初审", "Budget|first_audit"], ["预算审批单终审", "Budget|last_audit"]].each do |m|
  #   tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: audit_user_type)
  #   tmp.parent = audit_budget_obj
  #   tmp.save
  # end

# ----协议采购-----------------------------------------------------------------------------------------
  xygh = Menu.find_or_initialize_by(name: "协议采购", is_show: true, user_type: all_ut)
  xygh.parent = yw
  xygh.save

  xygh_list = Menu.find_or_initialize_by(name: "我的订单", route_path: "/kobe/orders/my_list?r=3", can_opt_action: "Order|my_list", is_show: true, user_type: mp_ut)
  xygh_list.parent = xygh
  xygh_list.save

  [
    ["下单采购", "Order|cart_order", "/kobe/orders/cart_order"],
    ["买方确认", "Order|buyer_confirm", "/kobe/orders/buyer_confirm"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: mp_ut)
    tmp.parent = xygh_list
    tmp.save
  end

  audit_xygh = Menu.find_or_initialize_by(name: "审核协议订单", route_path: "/kobe/orders/list?r=3", can_opt_action: "Order|list_r3", is_show: true, user_type: audit_user_type)
  audit_xygh.parent = xygh
  audit_xygh.save


  [["协议订单初审", "Order|first_audit"], ["协议订单终审", "Order|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: audit_user_type)
    tmp.parent = audit_xygh
    tmp.save
  end

  xygh_seller_list = Menu.find_or_initialize_by(name: "我的协议订单", route_path: "/kobe/orders/seller_list?r=3", can_opt_action: "Order|seller_list", is_show: true, user_type: supplier_user_type)
  xygh_seller_list.parent = xygh
  xygh_seller_list.save

  [
    ["卖方确认", "Order|agent_confirm", "/kobe/orders/agent_confirm"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: supplier_user_type)
    tmp.parent = xygh_seller_list
    tmp.save
  end

# ----协议议价-------------------------------------------------------------------------------------
  bargain = Menu.find_or_initialize_by(name: "协议议价", is_show: true, user_type: all_ut)
  bargain.parent = yw
  bargain.save

  my_bargain_list = Menu.find_or_initialize_by(name: "我的议价项目", route_path: "/kobe/bargains?t=my", can_opt_action: "Bargain|read", is_show: true, user_type: mp_ut)
  my_bargain_list.parent = bargain
  my_bargain_list.save

  [ ["查看议价项目", "Bargain|show", "/kobe/bargains/show"],
    ["新增议价项目", "Bargain|create", "/kobe/bargains/new"],
    ["修改议价项目", "Bargain|update", "/kobe/bargains/edit"],
    ["选择报价供应商", "Bargain|choose", "/kobe/bargains/choose"],
    ["查看可选产品", "Bargain|show_optional_products", "/kobe/bargains/show_optional_products"],
    ["查看报价产品", "Bargain|show_bid_details", "/kobe/bargains/show_bid_details"],
    ["提交议价项目", "Bargain|commit"],
    ["删除议价项目", "Bargain|update_destroy"],
    ["确认议价结果", "Bargain|confirm", "/kobe/bargains/confirm"],
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: mp_ut)
    tmp.parent = my_bargain_list
    tmp.save
  end

  confirm_bargain_list = Menu.find_or_initialize_by(name: "等待确认的议价项目", route_path: "/kobe/bargains?t=confirm", can_opt_action: "Bargain|read", is_show: true, user_type: mp_ut)
  confirm_bargain_list.parent = bargain
  confirm_bargain_list.save

  bargain_list = Menu.find_or_initialize_by(name: "辖区内议价项目", route_path: "/kobe/bargains", can_opt_action: "Bargain|read", is_show: true, user_type: mp_ut)
  bargain_list.parent = bargain
  bargain_list.save

  audit_bargain = Menu.find_or_initialize_by(name: "等待审核的议价项目", route_path: "/kobe/bargains/list", can_opt_action: "Bargain|list", is_show: true, user_type: audit_user_type)
  audit_bargain.parent = bargain
  audit_bargain.save

  audit_bargain_obj = Menu.find_or_initialize_by(name: "议价项目审核", route_path: "/kobe/bargains/audit", user_type: audit_user_type)
  audit_bargain_obj.parent = audit_bargain
  audit_bargain_obj.save

  [["议价项目初审", "Bargain|first_audit"], ["议价项目终审", "Bargain|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: audit_user_type)
    tmp.parent = audit_bargain_obj
    tmp.save
  end

  bargain_done_list = Menu.find_or_initialize_by(name: "已成交的议价项目", route_path: "/kobe/orders/my_list?r=16", can_opt_action: "Order|my_list", is_show: true, user_type: mp_ut)
  bargain_done_list.parent = bargain
  bargain_done_list.save

  bargain_bid_list = Menu.find_or_initialize_by(name: "等待报价的议价项目", route_path: "/kobe/bargains/bid_list?flag=1", can_opt_action: "Bargain|bid_list", is_show: true, user_type: supplier_user_type)
  bargain_bid_list.parent = bargain
  bargain_bid_list.save

  bargain_bid = Menu.find_or_initialize_by(name: "报价", can_opt_action: "Bargain|bid", route_path: "/kobe/bargains/bid", user_type: supplier_user_type)
  bargain_bid.parent = bargain_bid_list
  bargain_bid.save

  bargain_bidden_list = Menu.find_or_initialize_by(name: "已报价的议价项目", route_path: "/kobe/bargains/bid_list?flag=2", can_opt_action: "Bargain|bid_list", is_show: true, user_type: supplier_user_type)
  bargain_bidden_list.parent = bargain
  bargain_bidden_list.save

  show_bid = Menu.find_or_initialize_by(name: "查看报价", can_opt_action: "Bargain|show_bid_details", route_path: "/kobe/bargains/show_bid_details", user_type: supplier_user_type)
  show_bid.parent = bargain_bidden_list
  show_bid.save

  bargain_is_bid_list = Menu.find_or_initialize_by(name: "已中标的议价项目", route_path: "/kobe/bargains/bid_list?flag=3", can_opt_action: "Bargain|bid_list", is_show: true, user_type: supplier_user_type)
  bargain_is_bid_list.parent = bargain
  bargain_is_bid_list.save

  bargain_seller_list = Menu.find_or_initialize_by(name: "已成交的议价项目", route_path: "/kobe/orders/seller_list?r=16", can_opt_action: "Order|seller_list", is_show: true, user_type: supplier_user_type)
  bargain_seller_list.parent = bargain
  bargain_seller_list.save

# ----网上竞价-----------------------------------------------------------------------------------------
  ra_project = Menu.find_or_initialize_by(name: "网上竞价", is_show: true, user_type: all_ut)
  ra_project.parent = yw
  ra_project.save

  wsjj_list = Menu.find_or_initialize_by(name: "辖区内竞价项目", route_path: "/kobe/bid_projects", can_opt_action: "BidProject|read", is_show: true, user_type: mp_ut)
  wsjj_list.parent = ra_project
  wsjj_list.save

  [ ["发起竞价项目", "BidProject|create", "/kobe/bid_projects/new"],
    ["修改竞价项目", "BidProject|update", "/kobe/bid_projects/edit"],
    ["删除竞价项目", "BidProject|update_destroy"],
    ["提交网上竞价", "BidProject|commit"],
    ["选择中标人", "BidProject|choose", "/kobe/bid_projects/choose"],
    ["查看报价信息", "BidProjectBid|show", "/kobe/bid_project_bids/show"]
  ].each do |m|
    ac = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: mp_ut)
    ac.parent = wsjj_list
    ac.save
  end

  wsjj_done_list = Menu.find_or_initialize_by(name: "竞价成交项目", route_path: "/kobe/orders/my_list?r=11", can_opt_action: "Order|my_list", is_show: true, user_type: mp_ut)
  wsjj_done_list.parent = ra_project
  wsjj_done_list.save


  can_bid_list = Menu.find_or_initialize_by(name: "可报价的项目", route_path: "/kobe/bid_project_bids?flag=1", can_opt_action: "BidProjectBid|read", is_show: true, user_type: supplier_user_type)
  can_bid_list.parent = ra_project
  can_bid_list.save

  bid = Menu.find_or_initialize_by(name: "报价", can_opt_action: "BidProjectBid|bid", route_path: "/kobe/bid_project_bids/bid", user_type: supplier_user_type)
  bid.parent = can_bid_list
  bid.save

  bidden_list = Menu.find_or_initialize_by(name: "已报价的项目", route_path: "/kobe/bid_project_bids?flag=2", can_opt_action: "BidProjectBid|read", is_show: true, user_type: supplier_user_type)
  bidden_list.parent = ra_project
  bidden_list.save

  is_bid_list = Menu.find_or_initialize_by(name: "已中标的竞价项目", route_path: "/kobe/bid_project_bids?flag=3", can_opt_action: "BidProjectBid|read", is_show: true, user_type: supplier_user_type)
  is_bid_list.parent = ra_project
  is_bid_list.save

  wsjj_seller_list = Menu.find_or_initialize_by(name: "已成交的竞价项目", route_path: "/kobe/orders/seller_list?r=11", can_opt_action: "Order|seller_list", is_show: true, user_type: supplier_user_type)
  wsjj_seller_list.parent = ra_project
  wsjj_seller_list.save

  audit_wsjj = Menu.find_or_initialize_by(name: "等待审核的竞价项目", route_path: "/kobe/bid_projects/list", can_opt_action: "BidProject|list", is_show: true, user_type: audit_user_type)
  audit_wsjj.parent = ra_project
  audit_wsjj.save

  audit_wsjj_obj = Menu.find_or_initialize_by(name: "竞价项目审核", route_path: "/kobe/bid_projects/audit", user_type: audit_user_type)
  audit_wsjj_obj.parent = audit_wsjj
  audit_wsjj_obj.save

  [["网上竞价初审", "BidProject|first_audit"], ["网上竞价终审", "BidProject|last_audit"]].each do |m|
    a = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: audit_user_type)
    a.parent = audit_wsjj_obj
    a.save
  end

# ----定点采购-----------------------------------------------------------------------------------------
  ddcg = Menu.find_or_initialize_by(name: "定点采购", is_show: true, user_type: mp_ut)
  ddcg.parent = yw
  ddcg.save

  ddcg_list = Menu.find_or_initialize_by(name: "我的定点项目", route_path: "/kobe/orders/my_list?r=2", can_opt_action: "Order|my_list", is_show: true, user_type: mp_ut)
  ddcg_list.parent = ddcg
  ddcg_list.save

  [
    ["录入定点项目", "Order|create", "/kobe/orders/new"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: mp_ut)
    tmp.parent = ddcg_list
    tmp.save
  end

  audit_ddcg = Menu.find_or_initialize_by(name: "等待审核的定点项目", route_path: "/kobe/orders/list?r=2", can_opt_action: "Order|list_r2", is_show: true, user_type: audit_user_type)
  audit_ddcg.parent = ddcg
  audit_ddcg.save

  [["定点项目初审", "Order|first_audit"], ["定点项目终审", "Order|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: audit_user_type)
    tmp.parent = audit_ddcg
    tmp.save
  end

# ----个人采购-----------------------------------------------------------------------------------------
  grcg = Menu.find_or_initialize_by(name: "个人采购", is_show: true, user_type: mp_ut)
  grcg.parent = yw
  grcg.save

  grcg_list = Menu.find_or_initialize_by(name: "我的个人订单", route_path: "/kobe/orders/my_list?r=9", can_opt_action: "Order|my_list", is_show: true, user_type: mp_ut)
  grcg_list.parent = grcg
  grcg_list.save

  audit_grcg = Menu.find_or_initialize_by(name: "审核个人订单", route_path: "/kobe/orders/list?r=9", can_opt_action: "Order|list_r9", is_show: true, user_type: manage_user_type)
  audit_grcg.parent = grcg
  audit_grcg.save

  [["个人订单初审", "Order|first_audit"], ["个人订单终审", "Order|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = audit_grcg
    tmp.save
  end

  all_grcg = Menu.find_or_initialize_by(name: "全部个人订单", route_path: "/kobe/orders/grcg_list", can_opt_action: "Order|grcg_list", is_show: true, user_type: manage_user_type)
  all_grcg.parent = grcg
  all_grcg.save

# ----采购计划管理-------------------------------------------------------------------------------------
  plan = Menu.find_or_initialize_by(name: "采购计划管理", is_show: true, user_type: mp_ut)
  plan.parent = yw
  plan.save

  # ----采购计划项目管理-------------------------------------------------------------------------------
  plan_item = Menu.find_or_initialize_by(name: "制定采购计划", route_path: "/kobe/plan_items", can_opt_action: "PlanItem|read", is_show: true, user_type: manage_user_type)
  plan_item.parent = plan
  plan_item.save

  [ ["查看计划", "PlanItem|show", "/kobe/plan_items/show"],
    ["增加计划", "PlanItem|create", "/kobe/plan_items/new"],
    ["修改计划", "PlanItem|update", "/kobe/plan_items/edit"],
    ["提交计划", "PlanItem|commit"],
    ["删除计划", "PlanItem|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: manage_user_type)
    tmp.parent = plan_item
    tmp.save
  end

  plan_items_list = Menu.find_or_initialize_by(name: "正在报送的计划", route_path: "/kobe/plan_items/list", can_opt_action: "PlanItem|list", is_show: true, user_type: mp_ut)
  plan_items_list.parent = plan
  plan_items_list.save

  [ ["计划要求明细", "PlanItem|show", "/kobe/plan_items/show"],
    ["录入采购计划", "Plan|item_list", "/kobe/plans/item_list"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: mp_ut)
    tmp.parent = plan_items_list
    tmp.save
  end

  plan_list = Menu.find_or_initialize_by(name: "辖区内采购计划", route_path: "/kobe/plans", can_opt_action: "Plan|read", is_show: true, user_type: mp_ut)
  plan_list.parent = plan
  plan_list.save

  [ ["查看计划", "Plan|show", "/kobe/plans/show"],
    ["新增计划", "Plan|create", "/kobe/plans/new"],
    ["修改计划", "Plan|update", "/kobe/plans/edit"],
    ["提交计划", "Plan|commit"],
    ["删除计划", "Plan|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: mp_ut)
    tmp.parent = plan_list
    tmp.save
  end

  audit_plan = Menu.find_or_initialize_by(name: "等待审核的计划", route_path: "/kobe/plans/list", can_opt_action: "Plan|list", is_show: true, user_type: audit_user_type)
  audit_plan.parent = plan
  audit_plan.save

  audit_plan_obj = Menu.find_or_initialize_by(name: "计划审核", route_path: "/kobe/plans/audit", user_type: audit_user_type)
  audit_plan_obj.parent = audit_plan
  audit_plan_obj.save

  [["计划初审", "Plan|first_audit"], ["计划终审", "Plan|last_audit"]].each do |m|
    tmp =Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: audit_user_type)
    tmp.parent = audit_plan_obj
    tmp.save
  end

# ----日常费用报销类别---------------------------------------------------------------------------------
  daily_cost = Menu.find_or_initialize_by(name: "日常费用报销", is_show: false, user_type: manage_user_type)
  daily_cost.parent = yw
  daily_cost.save

  daily_cost_category = Menu.find_or_initialize_by(name: "维护开销类别", route_path: "/kobe/daily_categories", can_opt_action: "DailyCategory|read", is_show: false, user_type: manage_user_type)
  daily_cost_category.parent = daily_cost
  daily_cost_category.save

  [ ["增加开销类别", "DailyCategory|create"],
    ["修改开销类别", "DailyCategory|update"],
    ["删除开销类别", "DailyCategory|update_destroy"],
    ["移动开销类别", "DailyCategory|move"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = daily_cost_category
    tmp.save
  end

# ---日常费用报销--------------------------------------------------------------------------------------
  cost_index = Menu.find_or_initialize_by(name: "日常报销清单", route_path: "/kobe/daily_costs", can_opt_action: "DailyCost|read", is_show: false, user_type: manage_user_type)
  cost_index.parent = daily_cost
  cost_index.save

  [
    ["新增报销项目", "DailyCost|create", "/kobe/daily_costs/new"],
    ["修改报销项目", "DailyCost|update", "/kobe/daily_costs/edit"],
    ["提交报销项目", "DailyCost|commit"],
    ["删除报销项目", "DailyCost|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: manage_user_type)
    tmp.parent = cost_index
    tmp.save
  end

  audit_cost = Menu.find_or_initialize_by(name: "等待审核的报销项目", route_path: "/kobe/daily_costs/list", can_opt_action: "DailyCost|list", is_show: false, user_type: manage_user_type)
  audit_cost.parent = daily_cost
  audit_cost.save

  audit_cost_obj = Menu.find_or_initialize_by(name: "报销项目审核", route_path: "/kobe/daily_costs/audit", user_type: manage_user_type)
  audit_cost_obj.parent = audit_cost
  audit_cost_obj.save

  [["报销项目初审", "DailyCost|first_audit"], ["报销项目终审", "DailyCost|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = audit_cost_obj
    tmp.save
  end

# ----车辆信息维护-------------------------------------------------------------------------------------
  fixed_asset = Menu.find_or_initialize_by(name: "车辆信息维护", is_show: false, user_type: manage_user_type)
  fixed_asset.parent = yw
  fixed_asset.save

  fixed_asset_list = Menu.find_or_initialize_by(name: "车辆信息维护",route_path: "/kobe/fixed_assets", can_opt_action: "FixedAsset|read", is_show: false, user_type: manage_user_type)
  fixed_asset_list.parent = fixed_asset
  fixed_asset_list.save

  [ ["增加车辆信息", "FixedAsset|create", "/kobe/fixed_assets/new"],
    ["修改车辆信息", "FixedAsset|update", "/kobe/fixed_assets/edit"],
    ["删除车辆信息", "FixedAsset|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: manage_user_type)
    tmp.parent = fixed_asset_list
    tmp.save
  end

# ---车辆费用报销--------------------------------------------------------------------------------------
  asset_index = Menu.find_or_initialize_by(name: "车辆费用报销", route_path: "/kobe/asset_projects", can_opt_action: "AssetProject|read", is_show: false, user_type: manage_user_type)
  asset_index.parent = fixed_asset
  asset_index.save

  [
    ["新增报销项目", "AssetProject|create", "/kobe/asset_projects/new"],
    ["修改报销项目", "AssetProject|update", "/kobe/asset_projects/edit"],
    ["提交报销项目", "AssetProject|commit"],
    ["删除报销项目", "AssetProject|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: manage_user_type)
    tmp.parent = asset_index
    tmp.save
  end

  audit_asset = Menu.find_or_initialize_by(name: "等待审核的报销项目", route_path: "/kobe/asset_projects/list", can_opt_action: "AssetProject|list", is_show: false, user_type: manage_user_type)
  audit_asset.parent = fixed_asset
  audit_asset.save

  audit_asset_obj = Menu.find_or_initialize_by(name: "报销项目审核", route_path: "/kobe/asset_projects/audit", user_type: manage_user_type)
  audit_asset_obj.parent = audit_asset
  audit_asset_obj.save

  [["报销项目初审", "AssetProject|first_audit"], ["报销项目终审", "AssetProject|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = audit_asset_obj
    tmp.save
  end

# ----单位及用户管理-----------------------------------------------------------------------------------
  dep = Menu.find_or_create_by(name: "单位及用户管理", icon: "fa-users", is_auto: true, is_show: true, user_type: all_ut)

  dep_p = Menu.find_or_initialize_by(name: "组织机构管理", route_path: "/kobe/departments", can_opt_action: "Department|read", is_show: true, is_auto: true, user_type: all_ut)
  dep_p.parent = dep
  dep_p.save

  [ ["增加下属单位", "Department|create", false, all_ut],
    ["修改单位信息", "Department|update", true, all_ut],
    ["上传附件", "Department|upload", true, supplier_user_type],
    ["分配人员账号", "Department|add_user", false, all_ut],
    ["维护开户银行", "Department|bank", true, supplier_user_type],
    ["提交", "Department|commit", true, supplier_user_type],
    ["删除单位", "Department|update_destroy", false, manage_user_type],
    ["冻结单位", "Department|freeze", false, manage_user_type],
    ["恢复单位", "Department|recover", false, manage_user_type],
    ["移动单位", "Department|move", false, manage_user_type]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], is_auto: m[2], user_type: m[3])
    tmp.parent = dep_p
    tmp.save
  end

  dep_list = Menu.find_or_initialize_by(name: "供应商管理", route_path: "/kobe/departments/search", can_opt_action: "Department|search", is_show: true, user_type: manage_user_type)
  dep_list.parent = dep
  dep_list.save

  audit_dep = Menu.find_or_initialize_by(name: "等待审核的供应商", route_path: "/kobe/departments/list", can_opt_action: "Department|list", is_show: true, user_type: manage_user_type)
  audit_dep.parent = dep
  audit_dep.save

  audit_dep_obj = Menu.find_or_initialize_by(name: "供应商审核", route_path: "/kobe/departments/audit", user_type: manage_user_type)
  audit_dep_obj.parent = audit_dep
  audit_dep_obj.save

  [["供应商初审", "Department|first_audit"], ["供应商终审", "Department|last_audit"]].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    tmp.parent = audit_dep_obj
    tmp.save
  end

# ----后台管理-----------------------------------------------------------------------------------------
  main = Menu.find_or_create_by(name: "后台管理", route_path: "/main", user_type: all_ut)

  user = Menu.find_or_initialize_by(name: "个人信息", route_path: "/kobe/users", can_opt_action: "User|read", is_auto: true, user_type: all_ut)
  user.parent = main
  user.save

  [ ["修改个人信息", "User|update", true, all_ut],
    ["重置密码", "User|reset_password", false, all_ut],
    ["冻结用户", "User|freeze", false, all_ut],
    ["恢复用户", "User|recover", false, all_ut],
    ["user_admin","User|admin", false, manage_user_type]
  ].each do |u|
    tmp = Menu.find_or_initialize_by(name: u[0], can_opt_action: u[1], is_auto: u[2], user_type: u[3])
    tmp.parent = user
    tmp.save
  end

  yjjy = Menu.find_or_initialize_by(name: "意见反馈", route_path: "/kobe/faqs/yjjy_list", can_opt_action: "Faq|yjjy_list", is_auto: true, user_type: all_ut)
  yjjy.parent = main
  yjjy.save

  new_yjjy = Menu.find_or_initialize_by(name: "新增意见建议", route_path: "/kobe/faqs/new?catalog=yjjy", can_opt_action: "Faq|new", is_auto: true, user_type: all_ut)
  new_yjjy.parent = yjjy
  new_yjjy.save

# ----公告管理-----------------------------------------------------------------------------------------
  article = Menu.find_or_create_by(name: "公告管理", icon: "fa-tag", is_show: true, user_type: manage_user_type)

  article_list = Menu.find_or_initialize_by(name: "公告列表", route_path: "/kobe/articles", can_opt_action: "Article|read", is_show: true, user_type: manage_user_type)
  article_list.parent = article
  article_list.save

  [ ["发布公告", "Article|create", "/kobe/articles/new"],
    ["修改公告", "Article|update", "/kobe/articles/edit"],
    ["删除公告", "Article|update_destroy"],
    ["提交公告", "Article|commit"]
  ].each do |m|
    ac = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: manage_user_type)
    ac.parent = article_list
    ac.save
  end

  audit_article = Menu.find_or_initialize_by(name: "等待审核的公告", route_path: "/kobe/articles/list", can_opt_action: "Article|list", is_show: true, user_type: manage_user_type)
  audit_article.parent = article
  audit_article.save

  audit_article_obj = Menu.find_or_initialize_by(name: "公告审核", route_path: "/kobe/articles/audit", user_type: manage_user_type)
  audit_article_obj.parent = audit_article
  audit_article_obj.save

  [["公告初审", "Article|first_audit"], ["公告终审", "Article|last_audit"]].each do |m|
    a = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    a.parent = audit_article_obj
    a.save
  end

  article_catalog = Menu.find_or_initialize_by(name: "公告栏目管理", route_path: "/kobe/article_catalogs", can_opt_action: "ArticleCatalog|read", is_show: true, user_type: manage_user_type)
  article_catalog.parent = article
  article_catalog.save

  [ ["增加栏目", "ArticleCatalog|create"],
    ["修改栏目", "ArticleCatalog|update"],
    ["删除栏目", "ArticleCatalog|update_destroy"],
    ["移动栏目", "ArticleCatalog|move"]
  ].each do |m|
    ac = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
    ac.parent = article_catalog
    ac.save
  end

# ----政策法规、相关下载、常见问题、意见建议-----------------------------------------------------------
  faq_list = Menu.find_or_initialize_by(name: "Q&A", route_path: "/kobe/faqs", can_opt_action: "Faq|read", is_show: true, user_type: manage_user_type)
  faq_list.parent = article
  faq_list.save

  [ ["增加Q&A", "Faq|create", manage_user_type, "/kobe/faqs/new"],
    ["修改Q&A", "Faq|update", manage_user_type, "/kobe/faqs/edit"],
    ["删除Q&A", "Faq|update_destroy", manage_user_type],
    ["提交Q&A", "Faq|commit", manage_user_type],
    ["回复意见建议", "Faq|reply", manage_user_type, "/kobe/faqs/reply"]
  ].each do |m|
    ac = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: m[2], route_path: m[3])
    ac.parent = faq_list
    ac.save
  end

# ----数据统计与分析-----------------------------------------------------------------------------------
  tongji = Menu.find_or_create_by(name: "数据统计与分析", icon: "fa-bar-chart-o", is_show: true, user_type: mp_ut)

  all_tj = Menu.find_or_initialize_by(name: "整体情况统计", route_path: "/kobe/tongji", can_opt_action: "Order|tongji", is_show: true, user_type: mp_ut)
  all_tj.parent = tongji
  all_tj.save

  item_dep_tj = Menu.find_or_initialize_by(name: "入围供应商销量统计", route_path: "/kobe/tongji/item_dep_sales", can_opt_action: "Order|item_dep_sales", is_show: true, user_type: manage_user_type)
  item_dep_tj.parent = tongji
  item_dep_tj.save

# ----系统设置-----------------------------------------------------------------------------------------
  setting = Menu.find_or_create_by(name: "系统设置", icon: "fa-cogs", is_show: true, user_type: manage_user_type)

# ----品目管理-----------------------------------------------------------------------------------------
  category = Menu.find_or_initialize_by(name: "品目管理", route_path: "/kobe/categories", can_opt_action: "Category|read", is_show: true, user_type: manage_user_type)
  category.parent = setting
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

# ----入围项目管理-----------------------------------------------------------------------------------
  item = Menu.find_or_initialize_by(name: "入围项目管理", route_path: "/kobe/items", can_opt_action: "Item|read", is_show: true, user_type: manage_user_type)
  item.parent = setting
  item.save

  [ ["增加项目", "Item|create", "/kobe/items/new"],
    ["修改项目", "Item|update", "/kobe/items/edit"],
    ["查看项目", "Item|show", "/kobe/items/show"],
    ["提交项目", "Item|commit"],
    ["停止项目", "Item|pause"],
    ["恢复项目", "Item|recover"],
    ["删除项目", "Item|update_destroy"],
    ["供应商分级", "Item|classify", "/kobe/items/classify"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: manage_user_type)
    tmp.parent = item
    tmp.save
  end

#-----菜单管理----------------------------------------------------------------------------------------
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

  # contract_template = Menu.find_or_initialize_by(name: "合同模板", route_path: "/kobe/contract_templates", can_opt_action: "ContractTemplate|read", is_show: true, user_type: manage_user_type)
  # contract_template.parent = setting
  # contract_template.save

  # [ ["增加合同", "ContractTemplate|create"],
  #   ["修改合同", "ContractTemplate|update"],
  #   ["删除合同", "ContractTemplate|update_destroy"]
  # ].each do |m|
  #   tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], user_type: manage_user_type)
  #   tmp.parent = contract_template
  #   tmp.save
  # end

#-----待办事项----------------------------------------------------------------------------------------
  to_do_list = Menu.find_or_initialize_by(name: "待办事项", route_path: "/kobe/to_do_lists", can_opt_action: "ToDoList|read", is_show: true, user_type: manage_user_type)
  to_do_list.parent = setting
  to_do_list.save

  [ ["增加待办事项", "ToDoList|create", "/kobe/to_do_lists/new"],
    ["修改待办事项", "ToDoList|update", "/kobe/to_do_lists/edit"],
    ["删除待办事项", "ToDoList|update_destroy"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: manage_user_type)
    tmp.parent = to_do_list
    tmp.save
  end

#-----流程定制----------------------------------------------------------------------------------------
  rule = Menu.find_or_initialize_by(name: "流程定制", route_path: "/kobe/rules", can_opt_action: "Rule|read", is_show: true, user_type: manage_user_type)
  rule.parent = setting
  rule.save

  [ ["增加", "Rule|create", "/kobe/rules/new"],
    ["修改", "Rule|update", "/kobe/rules/edit"],
    ["删除", "Rule|update_destroy"],
    ["维护审核理由", "Rule|audit_reason"]
  ].each do |m|
    tmp = Menu.find_or_initialize_by(name: m[0], can_opt_action: m[1], route_path: m[2], user_type: manage_user_type)
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
    ["审核网上竞价需求", "/kobe/bid_projects/list?r=6", "/kobe/bid_projects/$$obj_id$$/audit"],
    ["审核网上竞价结果", "/kobe/bid_projects/list?r=7", "/kobe/bid_projects/$$obj_id$$/audit"],
    ["审核公告", "/kobe/articles/list", "/kobe/articles/$$obj_id$$/audit"],
    ["审核产品", "/kobe/products/list", "/kobe/products/$$obj_id$$/audit"],
    ["审核预算审批单", "/kobe/budgets/list", "/kobe/budgets/$$obj_id$$/audit"],
    ["审核定点采购项目", "/kobe/orders/list?r=2", "/kobe/orders/$$obj_id$$/audit"],
    ["审核协议供货项目", "/kobe/orders/list?r=3", "/kobe/orders/$$obj_id$$/audit"],
    ["卖方确认", "/kobe/orders/seller_list?r=3", "/kobe/orders/$$obj_id$$/agent_confirm"],
    ["买方确认", "/kobe/orders/my_list?r=3", "/kobe/orders/$$obj_id$$/buyer_confirm"],
    ["审核个人采购订单", "/kobe/orders/list?r=9", "/kobe/orders/$$obj_id$$/audit"],
    ["审核日常报销项目", "/kobe/daily_costs/list", "/kobe/daily_costs/$$obj_id$$/audit"],
    ["审核车辆报销项目", "/kobe/asset_projects/list", "/kobe/asset_projects/$$obj_id$$/audit"],
    ["审核协议议价结果", "/kobe/bargains/list", "/kobe/bargains/$$obj_id$$/audit"],
    ["等待报价", "/kobe/bargains/bid_list", "/kobe/bargains/$$obj_id$$/bid"],
    ["确认协议议价结果", "/kobe/bargains?t=confirm", "/kobe/bargains/$$obj_id$$/confirm"]
  ].each do |m|
    ToDoList.find_or_create_by(name: m[0], list_url: m[1], audit_url: m[2])
  end
end
