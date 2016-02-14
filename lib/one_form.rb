# -*- encoding : utf-8 -*-
# 单表表单
class OneForm < MyForm

  attr_accessor :options, :rules, :messages, :html_code
  attr_reader :xml, :obj, :table_name

  def initialize(obj, options = {})
    @xml = options[:xml].present? ? obj.class.send(options[:xml]) : obj.class.xml
    @obj = obj
    @options = options
    @table_name = options[:table] || obj.class.to_s.tableize
    @rules = []
    @messages = []
    @html_code = ""
    @options[:grid] ||= 2
    @options[:form_id] ||= "myform"
    @options[:method] ||= "post"
    @options[:button] = true if @options[:button].nil?
  end

end
