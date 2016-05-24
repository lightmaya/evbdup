# -*- encoding : utf-8 -*-
class AddUserIdToBatchAudits < ActiveRecord::Migration
  def change
    add_column :batch_audits, :user_id, :integer, :comment => "当前操作用户ID"
  end
end
