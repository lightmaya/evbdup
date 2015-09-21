# -*- encoding : utf-8 -*-
# 网上竞价
class CreateBidProjects < ActiveRecord::Migration
  def change
    create_table :bid_projects do |t|
    	t.integer :buy_type, :comment => "采购类别"
      t.string :top_dep_name, :comment => "上级单位"
      t.string :buyer_dep_name, :comment => "采购单位"
      t.string :invoice_title, :comment => "发票单位"
      t.string :buyer_name, :comment => "采购人姓名"
      t.string :buyer_phone, :comment => "采购人电话"
      t.string :buyer_mobile, :comment => "采购人手机"
      t.string :buyer_email, :comment => "采购人电子邮箱"
      t.string :buyer_add, :comment => "采购人地址"
      t.integer :lod, :comment => "明标或暗标"
      t.datetime :end_time, :comment => "截止时间"
      t.decimal :budget, :comment => "预算", :precision => 20, :scale => 2, :null => false, :default => 0
      t.text :req, :comment => "资质要求"
      t.text :remark, :comment => "备注信息"
      t.integer :status, :comment => "状态", :limit => 2, :default => 0,:null => false
      t.text :logs, :comment => "日志"

      t.string :name, :comment => "名称" 
      t.string :code, :comment => "编号" 
      t.integer :user_id

      t.timestamps
    end

    add_index :bid_projects, :status
    add_index :bid_projects, :user_id

    create_table :bid_items do |t|
    	t.integer :category_id, :comment => "品目ID"
    	t.integer :bid_project_id, :comment => "竞价ID"
      t.string :category_name
      t.string :brand_name, :comment => "参考品牌"
      t.string :xh, :comment => "参考型号"
      t.float :num, :comment => "购买数量"
      t.string :unit, :comment => "计量单位"
      t.integer :can_other, :comment => "是否允许投报其他型号的产品", :limit => 2, :default => 0, :null => false
      t.text :req, :comment => "技术指标和服务要求"
      t.text :remark, :comment => "备注信息"
      t.text :details

      t.text :logs, :comment => "日志"

      t.timestamps
    end

    add_index :bid_items, :category_id
    add_index :bid_items, :bid_project_id

  end
end
