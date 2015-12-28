# -*- encoding : utf-8 -*-
module LvUp

  extend ActiveSupport::Concern

  included do
    # has_many :attenders
  end

  # add your instance methods here
  def foo
     "foo"
  end

  # 通用生成编号 prefix + 8位日期 + 后4位ID
  def create_no(prefix = "WSJJ", column_name = "code")
    # 当前id格式化为4位
    uniq_id = ('%04d' % self.id)[-4...self.id.size]
    if send(column_name).blank?
      update(column_name => "#{prefix}-#{Time.now.to_s(:number)[0...10]}#{uniq_id}")
    end
  end

  # Application.yml top_type: [[0, "不置顶"], [1, "普通置顶"], [2, "标红置顶"]]
  def dict_value(method_name, key = nil)
    key ||= method_name
    values = ::Dictionary.send(key)
    return "" if values.blank?
    if values.is_a?(Array)
      values.find{|ary| ary.first == send(method_name)}.try(:last)
    elsif values.is_a?(Hash)
      values[method_name]
    else
      ""
    end
  end

  def error_msg
    msg = "（"
    errors.messages.map do |k, v|
      cname = I18n.t("simple_form.labels.defaults.#{k}")
      cname = I18n.t("simple_form.labels.#{self.class.to_s.downcase}.#{k}") if cname.include?("translation missing")
      cname = "" if cname.include?("translation missing")
      msg += "#{v.join('')} #{cname} 。"
    end
    msg += "）"
  end

  # 记录抓取日志，log_column是记录日志的字段，content_hash是记录的内容 ，如{"更新时间" => Time.new.strftime("%Y-%m-%d %H:%M:%S").to_s}
  def write_log(content_hash = {}, log_column = "log")
    return if content_hash.blank?
    unless self.send(log_column).blank?
      xml = Nokogiri::XML(self.send(log_column))
    else
      xml = Nokogiri::XML::Document.new()
      xml.encoding = "UTF-8"
      xml << "<logs>"
    end
    node = xml.root.add_child("<log>").first
    node["操作时间"] = Time.new.strftime("%Y-%m-%d %H:%M:%S").to_s
    content_hash.each do |k, v|
      node[k.to_s] = v
    end

    update({log_column.to_sym => xml.to_s})
  end

  def wlog(do_want, username = "系统", content_hash = {})
    content_hash.merge!({"操作人" => username, "事件" => do_want})
    log_column = content_hash[:log_column] || "log"
    write_log(content_hash, log_column)
  end

  # good.update_log({"操作" => "抓取报价"}, {"更新时间" => Time.now.to_s})
  # update goods set log = UpdateXML(log,'/logs/log[attribute::操作="抓取报价"]/attribute::更新时间',concat('更新时间=\"',now(),'\"')) where id = 39639
  def update_log(condition_hash = {}, value_hash = {}, log_column = "log")
    return nil unless log = self.send(log_column)
    return nil unless log_doc = Nokogiri::XML(log) rescue nil
    selector = "log"
    condition_hash.each{|k, v| selector += "[#{k.to_s}='#{v}']"}
    return nil if log_doc.search(selector).first.blank?
    value_hash.each{|k, v| log_doc.search(selector).map{|dom| dom[k.to_s] = v}}
    update({log_column.to_sym => log_doc.to_s})
  end

  def uniq_log(condition_hash = {}, log_column = "log")
    return nil unless log = self.send(log_column)
    return nil unless log_doc = Nokogiri::XML(log) rescue nil
    selector = "log"
    condition_hash.each{|k, v| selector += "[#{k.to_s}='#{v}']"}
    return nil if log_doc.search(selector).first.blank?
    size = log_doc.search(selector).size
    return true if size == 1
    log_doc.search(selector)[1..size-1].map(&:remove)
    update({log_column.to_sym => log_doc.to_s})
  end

  def write_or_update(condition_hash = {}, log_column = "log")
    write_log(condition_hash) unless update_log(condition_hash, {"更新时间" => Time.now.to_s})
  end

  # add your static(class) methods here
  module ClassMethods
    def bar
      "bar"
    end

    def log_p(msg, log_path = "log_p.log")
      @logger ||= Logger.new(Rails.root.join('log', "log_p.log"))
      @logger.info msg
    end
  end
end
