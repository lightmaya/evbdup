# -*- encoding : utf-8 -*-
class MsgUser < ActiveRecord::Base
  belongs_to :user
  belongs_to :msg

  scope :unread, -> { where(is_read: false) }

  Is_read = {0 => "未读", 1 => "已读"}

  def read!
  	update(is_read: true)
  end
end
