class CreateContractTemplates < ActiveRecord::Migration
  def change
    create_table :contract_templates do |t|
    	t.string :file_name, :comment => "文件名", :null => false
    	t.string :name, :comment => "模板名称", :null => false
    	t.string :url, :comment => "模板文件URL", :null => false, :default => "/kobe/orders/ht"
      t.integer :status, :comment => "状态", :limit => 2, :default => 0 , :null => false
      t.text :content, :comment => "内容"
      t.text :details, :comment => "明细"
      t.text :logs, :comment => "日志"

      t.timestamps
    end
  end
end
