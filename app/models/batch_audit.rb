# -*- encoding : utf-8 -*-
class BatchAudit < ActiveRecord::Base

  # 补漏批量审核 用于定时任务
  def self.send_missing_audit
    p "#{begin_time = Time.now} in BatchAudit.send_missing_audit....."
    succ = 0
    all_audit = self.all
    all_audit.each do |e|
      # {obj_id: id, class_name: model_name.to_s, next: params[:audit_next], yijian: params[:audit_yijian], liyou: params[:audit_liyou]}
      model_name = e.class_name.constantize
      obj = model_name.find_by(id: e.obj_id)
      # 审核
      cs = obj.get_current_step
      act = cs.is_a?(Hash) ? cs["name"] : "审核#{e.yijian}"
      logs = e.create_logs(act, "审核#{e.yijian}，#{obj.audit_next_hash[e.next]}。审核理由：#{e.liyou}")
      eval("obj.go_to_audit_#{e.next}(e.yijian, logs, e.next_user_id)")
      # 删除batch_audit
      e.destroy
      succ += 1
    end
    p "#{end_time = Time.now} BatchAudit.send_missing_audit end... #{(end_time - begin_time)/60} min ---succ: #{succ}/#{all_audit.size}"
  end

  def create_logs(action, remark)
    doc = Nokogiri::XML::Document.new
    doc.encoding = "UTF-8"
    doc << "<root>"
    user = User.find_by(id: self.user_id)
    user = User.where(login: Dictionary.daboss).first if user.blank?
    node = doc.root.add_child("<node>").first
    node["操作时间"] = Time.now.to_s(:db)
    node["操作人ID"] = user.id.to_s
    node["操作人姓名"] = user.name.to_s
    node["操作人单位"] = user.department.nil? ? "暂无" : user.department.name.to_s
    node["操作内容"] = action
    node["当前状态"] = "$STATUS$"
    node["备注"] = remark
    return node.to_s
  end

end
