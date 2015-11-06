class CreateFixedAssets < ActiveRecord::Migration
  def change
    create_table :fixed_assets do |t|
    	t.belongs_to :category
    	t.string :category_name
    	t.string :category_code  , :null => false , :comment => '车类别'
    	t.string :sn , :null => false
      t.string :name 
      t.decimal :gouzhi_jiage , :precision => 13, :scale => 2, :null => false, :default => 0 , :comment => '购置价格'
      t.decimal :gouzhi_shui  , :precision => 13, :scale => 2, :null => false, :default => 0 , :comment => '购置税'
      t.date :gouzhi_riqi  , :comment => '购置日期' , :null => false
      t.date :qiyong_riqi  , :comment => '启用日期' , :null => false
			t.date :baofei_riqi  , :comment => '报废日期' 
			t.date :zhuanyi_riqi  , :comment => '转移日期' 
			t.string :zhuanyi_danwei , :comment => '转移单位'
			t.decimal :zhejiulv , :precision => 4 , :scale => 2 , :null => false 
			t.string :fuzeren 
			t.belongs_to :user   , :comment => "用户ID", :null => false, :default => 0
      t.belongs_to :department  , :comment => "用户"
      t.string :dep_name , :comment => '真实单位'
      t.string :bumen  , :comment => '使用部门'
      t.integer :status    , :comment => "状态", :limit => 2, :default => 0 ,:null => false
      t.text :details    , :comment => "明细"
      t.text :logs       , :comment => "日志"
      t.timestamps
    end
  end
end
