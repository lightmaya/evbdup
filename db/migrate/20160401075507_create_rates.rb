# -*- encoding : utf-8 -*-
class CreateRates < ActiveRecord::Migration
  def change
    create_table :rates do |t|
      t.decimal :jhsd, :precision => 13, :scale => 2, :comment => "交货速度"
      t.decimal :fwtd, :precision => 13, :scale => 2, :comment => "服务态度"
      t.decimal :cpzl, :precision => 13, :scale => 2, :comment => "产品质量"
      t.decimal :jjwt, :precision => 13, :scale => 2, :comment => "解决问题能力"
      t.decimal :dqhf, :precision => 13, :scale => 2, :comment => "定期回访"
      t.decimal :xcfw, :precision => 13, :scale => 2, :comment => "现场服务"
      t.decimal :bpbj, :precision => 13, :scale => 2, :comment => "备品备件"
      t.decimal :total, :precision => 13, :scale => 2, :comment => "评价得分"
      t.text :summary, :comment => "备注"
      t.belongs_to :user               , :comment => "用户ID", :null => false, :default => 0
      t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
      t.text :details                  , :comment => "明细"
      t.text :logs                     , :comment => "日志", :limit => 4294967295
      t.timestamps
    end
  end

  add_column :orders, :rate_id, :integer, :comment => "评价id"
  add_column :orders, :rate_total, :decimal, :precision => 13, :scale => 2, :comment => "评价得分"

end
