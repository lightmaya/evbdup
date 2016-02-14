# -*- encoding : utf-8 -*-
# gem 'settingslogic'
class Dictionary < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env

  # 将application.yml中的状态status_hash 转换成status_array
  def all_status_array
    status_arr = []
    self.status_hash.each do |k, v|
      status_arr << (k + v)
    end
    return status_arr
  end

  # 格式化application.yml中的status_hash 将字符串类型的状态变成数字类型
  def status_hash
    ha = {}
    self.all_status.each do |k, v|
      ha[[k.first, k.last.to_i]] = v
    end
    return ha
  end

end
