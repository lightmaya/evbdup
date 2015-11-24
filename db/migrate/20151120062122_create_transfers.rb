class CreateTransfers < ActiveRecord::Migration
  def change
    create_table :transfers do |t|
    	t.string :name                   , :comment => "项目名称", :null => false
    	t.string :sn                     , :comment => "项目编号"
      t.belongs_to :department  , :comment => "单位"
      t.string :dep_name           , :comment => "采购单位"
      t.string :dep_code             , :comment => "采购单位real_ancestry"
     	t.string :dep_man              , :comment => "采购单位联系人"
      t.string :dep_tel              , :comment => "采购单位座机"
      t.string :dep_mobile              , :comment => "采购单位联系人电话"
      t.string :dep_addr             , :comment => "采购单位地址"
    	t.decimal :total                 , :comment => "总金额", :precision => 13, :scale => 2, :null => false, :default => 0
    	t.text :summary                  , :comment => "基本情况（备注）"
    	t.belongs_to :user               , :comment => "用户ID", :null => false, :default => 0
    	t.integer :status                , :comment => "状态", :limit => 2, :default => 0 ,:null => false
    	t.text :details                  , :comment => "明细"
    	t.text :logs                     , :comment => "日志"

      t.timestamps
    end

    create_table :transfer_items do |t|
      t.belongs_to :transfer      , :comment => "主表ID", :null => false, :default => 0
      t.belongs_to :category    , :comment => "品目"
    	t.string :category_code   , :comment => "品目ancestry", :null => false
      t.string :category_name   , :comment => "品目名称"
    	t.string :unit            , :comment => "计量单位"
    	t.decimal :original_price   , :comment => "资产原值", :precision => 13, :scale => 2
    	t.decimal :net_price      , :comment => "资产净值", :precision => 13, :scale => 2
    	t.decimal :transfer_price   , :comment => "转让资金", :precision => 13, :scale => 2, :null => false, :default => 0
    	t.integer :num       , :comment => "数量", :default => 0 ,:null => false
    	t.integer :product_status         , :comment => "设备状态"
      t.text :description       , :comment => "技术规格或产品说明"
      t.text :summary           , :comment => "基本情况（备注）"
      t.text :details           , :comment => "明细"

      t.timestamps
    end

    create_table :transfer_uploads do |t|
    	t.belongs_to :master, :default => 0
      t.string   "upload_file_name"   , :comment => "文件名称"
      t.string   "upload_content_type", :comment => "文件类型"
      t.integer  "upload_file_size"   , :comment => "文件大小"
      t.datetime "upload_updated_at"  , :comment => "时间戳"
      t.timestamps
    end
    

    add_index :transfers, :sn, :unique => true
    add_index :transfer_items, :transfer_id
    add_index :transfer_items, :category_code
    add_index :transfer_uploads, [:master_id]

  end
end
