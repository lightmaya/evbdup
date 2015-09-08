# -*- encoding : utf-8 -*-
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
  [["数据统计与分析",  "fa-bar-chart-o"], ["公告管理", "fa-tag"]].each do |option|
    Menu.create(:name => option[0], :icon => option[1], :is_show => true)
  end

  item_manage = Menu.create(:name => "入围产品管理", :is_show => true)
  item_list = Menu.create(:name => "我的入围项目", :route_path => "/kobe/items/list", :can_opt_action => "Item|list", :is_show => true, :parent => item_manage)
  [["查看项目", "Item|show"],["录入产品", "Product|item_list"],["新增产品", "Product|create"], ["修改产品", "Product|update"], ["查看产品", "Product|read"],  ["删除产品", "Product|update_destroy"], ["冻结产品", "Product|freeze"], ["恢复产品", "Product|recover"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => item_list)
  end
  product = Menu.create(:name => "我的入围产品", :route_path => "/kobe/products", :can_opt_action => "Product|read", :is_show => true, :parent => item_manage)

  order = Menu.create(:name => "订单管理", :icon => "fa-tasks", :is_show => true)
  Menu.create(:name => "辖区内采购项目", :route_path => "/kobe/orders", :can_opt_action => "Order|read", :is_show => true, :parent => order)
  ddcg = Menu.create(:name => "定点采购", :is_show => true, :parent => order)
  ddcg_list = Menu.create(:name => "我的定点采购项目", :route_path => "/kobe/orders/ddcg_list", :can_opt_action => "Order|ddcg_list", :is_show => true, :parent => ddcg)
  [["查看定点采购", "Order|read"],["增加定点采购", "Order|create"], ["修改定点采购", "Order|update"], ["提交定点采购", "Order|commit"], ["删除定点采购", "Order|update_destroy"], ["打印定点采购订单", "Order|print"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => ddcg_list)
  end
  audit_ddcg = Menu.create(:name => "审核定点采购", :route_path => "/kobe/orders/audit_ddcg", :can_opt_action => "Order|audit_ddcg", :is_show => true, :parent => ddcg)
  [["定点采购初审", "Order|first_audit"], ["定点采购终审", "Order|last_audit"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => audit_ddcg)
  end

  dep = Menu.create(:name => "单位及用户管理", :icon => "fa-users", :is_auto => true, :is_show => true)
  dep_p = Menu.create(:name => "单位管理", :route_path => "/kobe/departments", :can_opt_action => "Department|read", :is_show => true, :is_auto => true, :parent => dep)
  [["增加下属单位", "Department|create"], ["修改单位信息", "Department|update", true], ["上传附件", "Department|upload", true], ["分配人员账号", "Department|add_user"], ["维护开户银行", "Department|bank", true], ["提交", "Department|commit", true], ["删除单位", "Department|update_destroy"], ["冻结单位", "Department|freeze"], ["恢复单位", "Department|recover"], ["移动单位", "Department|move"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :is_auto => m[2].present?, :parent => dep_p)
  end
  
  Menu.create(:name => "单位查询", :route_path => "/kobe/departments/search", :can_opt_action => "Department|search", :is_show => true, :parent => dep)

  audit_dep = Menu.create(:name => "审核单位", :route_path => "/kobe/departments/list", :can_opt_action => "Department|list", :is_show => true, :parent => dep)
  [["单位初审", "Department|first_audit"], ["单位终审", "Department|last_audit"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => audit_dep)
  end

  user = Menu.create(:name => "用户管理", :route_path => "/kobe/users", :can_opt_action => "User|read", :is_show => true, :is_auto => true, :parent => dep)
  [["修改用户", "User|update", true],["重置密码", "User|reset_password"],["冻结用户", "User|freeze"],["恢复用户", "User|recover"],["user_admin","User|admin"]].each do |u|
    Menu.create(:name => u[0], :can_opt_action => u[1], :is_auto => u[2].present?, :parent => user)
  end

  setting = Menu.create(:name => "系统设置", :icon => "fa-cogs", :is_show => true)

  item = Menu.create(:name => "入围项目管理", :route_path => "/kobe/items", :can_opt_action => "Item|read", :is_show => true, :parent => setting)
  [["增加项目", "Item|create"], ["修改项目", "Item|update"], ["提交项目", "Item|commit", true], ["停止项目", "Item|pause"], ["恢复项目", "Item|recover"], ["删除项目", "Item|update_destroy"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => item)
  end

  menu = Menu.create(:name => "菜单管理", :route_path => "/kobe/menus", :can_opt_action => "Menu|read", :is_show => true, :parent => setting)
  [["增加菜单", "Menu|create"], ["修改菜单", "Menu|update"], ["删除菜单", "Menu|update_destroy"], ["移动菜单", "Menu|move"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => menu)
  end

  category = Menu.create(:name => "品目管理", :route_path => "/kobe/categories", :can_opt_action => "Category|read", :is_show => true, :parent => setting)
  [["增加品目", "Category|create"], ["修改品目", "Category|update"], ["删除品目", "Category|update_destroy"],["冻结品目", "Category|freeze"],["恢复品目", "Category|recover"], ["移动品目", "Category|move"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => category)
  end

  contract_template = Menu.create(:name => "合同模板", :route_path => "/kobe/contract_templates", :can_opt_action => "ContractTemplate|read", :is_show => true, :parent => setting)
  [["增加合同", "ContractTemplate|create"], ["修改合同", "ContractTemplate|update"], ["删除合同", "ContractTemplate|update_destroy"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => contract_template)
  end

  to_do_list = Menu.create(:name => "待办事项", :route_path => "/kobe/to_do_lists", :can_opt_action => "ToDoList|read", :is_show => true, :parent => setting)
  [["增加待办事项", "ToDoList|create"], ["修改待办事项", "ToDoList|update"], ["删除待办事项", "ToDoList|update_destroy"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => to_do_list)
  end

  rule = Menu.create(:name => "流程定制", :route_path => "/kobe/rules", :can_opt_action => "Rule|read", :is_show => true, :parent => setting)
  [["增加", "Rule|create"], ["修改", "Rule|update"], ["删除", "Rule|update_destroy"], ["维护审核理由", "Rule|audit_reason"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :parent => rule)
  end

end

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