# -*- encoding : utf-8 -*-
class TaskQueue < ActiveRecord::Base
  belongs_to :to_do_list

  # 根据class_name和obj_id 获取obj
  def get_belongs_to_obj
    return self.class_name.constantize.find_by(id: self.obj_id)
  end

end
