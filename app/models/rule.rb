# -*- encoding : utf-8 -*-
class Rule < ActiveRecord::Base

	has_many :departments
	has_many :orders

	include AboutStatus

	# 中文意思 状态值 标签颜色 进度 
  def self.status_array
    [
      ["正常",0,"u",100],
      ["已删除",404,"red",0]
    ]
  end

  # 根据不同操作 改变状态
  def change_status_hash
    {
      "删除" => { 0 => 404 }
    }
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='')
    ["delete", "destroy"].include?(act) ? self.can_opt?("删除") : false
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	limited = [404]
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  def self.xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	      <node name='名称' column='name' class='required'/>
        <node name='编码' column='code'/>
        <node name='业务类型' column='yw_type' class='required' hint='用于区分订单的类型：ddcg、xygh、wsjj、Department、Product、ItemDepartment'/>
	    </root>
	  }
	end

  def self.tips
    Dictionary.tips.rule
	end

	# 根据rule xml 生成的n个实例 返回数组
	def create_rule_objs
		return [RuleStep.new] if self.rule.blank?
    arr = []
    Nokogiri::XML(self.rule).xpath("/root/step").each do |step|
      obj = RuleStep.new
      obj.attributes["name"] = step.attributes["name"].to_str
      step.children.each do |e|
      	next if e.text?
      	obj.attributes[e.name] = e.to_str
      end
      arr << obj
    end
    return arr
  end

  # 获取整个流程的实例数组 
  # 返回数组 [{"name"=>"总公司审核", "dep"=>"self.real_ancestry_level(2)","junior"=>[19], "senior"=>[20], "inflow"=>"self.status == 2", "outflow"=>"self.status == 404", "first_audit"=>"单位初审", "last_audit"=>"单位终审", "to_do_id"=>"1"}, {}, {}]
  def get_step_objs
    objs = []
    self.create_rule_objs.each do |obj|
      # 初审、终审权限转成数字类型的数组
      obj.attributes["junior"] = obj.attributes["junior"].split(",").map { |e| e.to_i }
      obj.attributes["senior"] = obj.attributes["senior"].split(",").map { |e| e.to_i }
      objs << obj.attributes
    end
    return objs
  end

  # 获取默认的审核理由 返回数组
  def get_audit_reason_arr
    arr = []
    Nokogiri::XML(self.audit_reason).css("node").each { |reason| arr << reason.to_str }
    return arr
  end

end
