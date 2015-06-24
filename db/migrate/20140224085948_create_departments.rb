# -*- encoding : utf-8 -*-
class CreateDepartments < ActiveRecord::Migration
  def change
    create_table :departments do |t|
		t.string :name                   , :comment => "单位名称", :null => false
		t.string :ancestry               , :comment => "祖先节点"
		t.integer :ancestry_depth        , :comment => "层级"
		t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
		t.string :short_name             , :comment => "单位简称"
		t.string :org_code               , :comment => "组织机构代码"
		t.string :legal_name             , :comment => "单位法人姓名"
		t.string :legal_number           , :comment => "单位法人身份证"
		t.integer :area_id               , :comment => "地区id"
		t.string :address                , :comment => "详细地址"
		t.string :post_code              , :comment => "邮编"
		t.string :website                , :comment => "公司网址"
		t.string :domain                 , :comment => "店铺域名"
		t.string :bank                   , :comment => "开户银行"
		t.string :bank_code              , :comment => "银行帐号"
		t.string :industry               , :comment => "行业类别"
		t.string :cgr_nature             , :comment => "单位性质"
		t.string :gys_nature             , :comment => "公司性质"
		t.string :capital                , :comment => "注册资金"
		t.string :license                , :comment => "营业执照"
		t.string :tax                    , :comment => "税务登记证"
		t.string :employee               , :comment => "职工人数"
		t.string :turnover               , :comment => "年营业额"
		t.string :tel                    , :comment => "电话（总机）"
		t.string :fax                    , :comment => "传真"
		t.string :categories             , :comment => "主营产品ID"
		t.string :lng                    , :comment => "经度"
		t.string :lat                    , :comment => "纬度"
		t.text :summary                  , :comment => "单位介绍"
		t.boolean :is_secret             , :comment => "是否保密单位", :default => 0 ,:null => false
		t.boolean :is_blacklist          , :comment => "是否在黑名单中", :default => 0 ,:null => false
		t.integer :sort                  , :comment => "排序号"
		t.text :details                  , :comment => "明细"
		t.text :logs                     , :comment => "日志"

		t.timestamps
    end
    
    add_index :departments, :name,                :unique => true
    # add_index :departments, :org_code,            :unique => true
    add_index :departments, :ancestry
  end
end