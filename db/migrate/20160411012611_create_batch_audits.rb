# -*- encoding : utf-8 -*-
class CreateBatchAudits < ActiveRecord::Migration
  def change
    create_table :batch_audits do |t|
      t.integer :obj_id, :comment => "实例ID", :default => 0 , :null => false
      t.string :class_name, :comment => "类名", :default => "Order" , :null => false
      t.string :next, :comment => "下一步"
      t.string :yijian, :comment => "审核意见"
      t.string :liyou, :comment => "审核理由"
      t.string :next_user_id, :comment => "转向下一个审核人"

      t.timestamps
    end
  end
end
