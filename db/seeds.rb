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
  [["订单管理",  "fa-tasks"], ["入围产品管理",  "fa-bookmark-o"], ["数据统计与分析",  "fa-bar-chart-o"], ["公告管理", "fa-tag"]].each do |option|
    Menu.create(:name => option[0], :icon => option[1], :is_show => true)
  end

  dep = Menu.create(:name => "单位及用户管理", :icon => "fa-users", :is_show => true)
  dep_p = Menu.create(:name => "采购单位管理", :route_path => "/kobe/departments", :can_opt_action => "Department|read", :is_show => true, :is_auto => true, :parent => dep)
  [["增加下属单位", "Department|create"], ["修改单位信息", "Department|update", true], ["上传附件", "Department|upload", true], ["分配人员账号", "Department|add_user"], ["维护开户银行", "Department|bank", true], ["提交", "Department|commit", true], ["删除单位", "Department|update_destroy"], ["冻结单位", "Department|freeze"], ["恢复单位", "Department|recover"], ["移动单位", "Department|move"]].each do |m|
    Menu.create(:name => m[0], :can_opt_action => m[1], :is_auto => m[2].present?, :parent => dep_p)
  end
  
  Menu.create(:name => "单位查询", :route_path => "/kobe/departments/search", :can_opt_action => "Department|search", :is_show => true, :parent => dep)

  user = Menu.create(:name => "用户管理", :route_path => "/kobe/users", :can_opt_action => "User|read", :is_show => true, :is_auto => true, :parent => dep)
  [["修改用户", "User|update", true],["重置密码", "User|reset_password"],["冻结用户", "User|freeze"],["恢复用户", "User|recover"],["user_admin","User|admin"]].each do |u|
    Menu.create(:name => u[0], :can_opt_action => u[1], :is_auto => u[2].present?, :parent => user)
  end

  setting = Menu.create(:name => "系统设置", :icon => "fa-cogs", :is_show => true)
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

end

if Category.first.blank?
  a = Category.create(:name => "办公物资", :status => 1) 
  b = Category.create(:name => "粮机物资", :status => 1) 
  ["计算机","打印机","复印机","服务器"].each do |option|
    Category.create(:name => option, :status => 1, :parent => a)
  end
  ["输送机","清理筛"].each do |option|
    Category.create(:name => option, :status => 1, :parent => b)
  end
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