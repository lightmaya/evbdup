# -*- encoding : utf-8 -*-
namespace :everyday do

  desc '生成采购单位后台main统计数据'
  task :create_cache_dep_main => :environment do
    p "#{begin_time = Time.now} in create_cache_dep_main....."

    deps = Department.where(status: Department.effective_status)
    succ = 0
    deps.each do |d|
      if d.cache_dep_main true
        succ += 1
        # p ".create_cache_dep_main succ: #{succ}/#{deps.size} old: #{d.id}"
      else
        p ".create_cache_dep_main_error dep_id: #{d.id}"
        log_p "[error]old_id: #{d.id} | #{d.errors.full_messages}" ,"create_cache_dep_main.log"
      end
    end

    p "#{end_time = Time.now} create_cache_dep_main end... #{(end_time - begin_time)/60} min ---succ: #{succ}/#{deps.size}"
  end

  desc "更新评价分"
  task :update_order_rate => :environment do
    p "#{begin_time = Time.now} in update_order_rate....."

    os = Order.where("rate_id is null and invoice_number is not null and invoice_number <> '' and status in (#{(Order.effective_status-[79, 86, 100]).join(", ")})").order(id: :desc)
    succ = 0
    os.each do |e|
      e.status = 93
      e.effective_time = e.updated_at if e.effective_time.blank?
      if e.effective_time + 45.days <= Time.now
        r = Rate.create(jhsd: 2, fwtd: 2, cpzl: 2, jjwt: 3.5, dqhf: 3.5, xcfw: 3.5, bpbj: 3.5, total: 20, summary: "用户超过45天未评价，按规定一律只得20分（系统自动评价）。")
        if r.present?
          e.rate_id = r.id
          e.rate_total = r.total
          e.status = 100
          e.logs = save_logs(e.logs, "评价", 100, "用户超过45天未评价，按规定一律只得20分（系统自动评价）。")
        else
          p ".update_order_rate_error [rate create error] order_id: #{e.id}"
          log_p "[error]order_id: #{e.id} | #{e.errors.full_messages}" ,"update_order_rate.log"
        end
      end
      if e.save
        succ += 1
        # p ".update_order_rate succ: #{succ}/#{os.size} order_id: #{e.id}"
      else
        p ".update_order_rate_error order_id: #{e.id}"
        log_p "[error]order_id: #{e.id} | #{e.errors.full_messages}" ,"update_order_rate.log"
      end
    end

    p "#{end_time = Time.now} update_order_rate end... #{(end_time - begin_time)/60} min ---succ: #{succ}/#{os.size}"

  end

  desc "批量审核"
  task :batch_audit => :environment do
    BatchAudit.send_missing_audit
  end

  # 输出日志到文件和控制台
  def self.log_p(msg, log_path = "data.log")
    @logger ||= Logger.new(Rails.root.join('log', log_path))
    @logger.info msg
  end

  # 清除历史遗留数据 插入日志
  def save_logs(xml, action, status, remark)
    user = User.find_by(login: 'zcl001')
    if xml.present?
      doc = Nokogiri::XML(xml)
    else
      doc = Nokogiri::XML::Document.new()
      doc.encoding = "UTF-8"
      doc << "<root>"
    end
    node = doc.root.add_child("<node>").first
    node["操作时间"] = Time.now.to_s(:db)
    node["操作人ID"] = user.id.to_s
    node["操作人姓名"] = user.name.to_s
    node["操作人单位"] = user.department.nil? ? "暂无" : user.department.name.to_s
    node["操作内容"] = action
    node["当前状态"] = status
    node["备注"] = remark
    return doc.to_s
  end

end
