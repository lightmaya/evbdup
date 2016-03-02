# -*- encoding : utf-8 -*-
class Rule < ActiveRecord::Base

  has_many :departments
  has_many :orders

  include AboutStatus

  default_value_for :status, 65

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [["正常", "65", "yellow", 100], ["已删除", "404", "dark", 100]]
    self.get_status_array(["正常", "已删除"])
    # [
    #   ["正常",0,"u",100],
    #   ["已删除",404,"red",0]
    # ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   {
  #     "删除" => { 0 => 404 }
  #   }
  # end

  # 根据action_name 判断obj有没有操作
  def cando(act='')
    ["delete", "destroy"].include?(act) ? self.can_opt?("删除") : false
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  # 	# 列表中不允许出现的
  # 	limited = [404]
  # 	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='名称' column='name' class='required'/>
        <node name='编码' column='code'/>
        <node name='业务类型' column='yw_type' hint='用于区分订单的类型：ddcg、xygh、wsjj、Department、Product、ItemDepartment'/>
      </root>
    }
  end

  def self.tips
    Dictionary.tips.rule
  end

  # 根据rule xml 生成的n个实例 返回数组
  def create_rule_objs
    return [RuleStep.new] if self.rule_xml.blank?
    arr = []
    Nokogiri::XML(self.rule_xml).xpath("/root/step").each do |step|
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

  # 检查流程对应的状态和菜单是否正确
  def self.check_status_and_menus
    str = ['false: ']
    self.all.each do |r|
      p "...#{r.name}.........................."
      Nokogiri::XML(r.rule_xml).css("step").each_with_index do |step, i|
        name = step["name"].to_str
        junior = Menu.find_by(id: step.at_css('junior').to_str).try(:name)
        senior = Menu.find_by(id: step.at_css('senior').to_str).try(:name)
        start_status = Dictionary.all_status.keys.find{ |e| e[1] == step.at_css('start_status').to_str }[0]
        return_status = Dictionary.all_status.keys.find{ |e| e[1] == step.at_css('return_status').to_str }[0]
        finish_status = Dictionary.all_status.keys.find{ |e| e[1] == step.at_css('finish_status').to_str }[0]
        to_do_id = ToDoList.find_by(id: step.at_css('to_do_id').to_str).try(:name)

        first_audit = step.at_css('first_audit').to_str
        last_audit = step.at_css('last_audit').to_str
        p "#{i+1}. #{name}"
        p "#{first_audit == junior}  junior: #{junior} | step.at_css('first_audit'): #{first_audit}"
        p "#{last_audit == senior}  senior: #{senior}  | step.at_css('last_audit'): #{last_audit}"
        p "=============================================================================="
        p "  start_status:  #{start_status}"
        p "  return_status: #{return_status}"
        p "  finish_status: #{finish_status}"
        p "  to_do_id:      #{to_do_id}"
        p "................................................................................."

        str << "...#{r.name}....junior: #{junior} | step.at_css('first_audit'): #{first_audit}" if first_audit != junior
        str << "...#{r.name}....senior: #{senior}  | step.at_css('last_audit'): #{last_audit}" if last_audit != senior

      end
    end
    str.each{ |e| p e }
    p str.size-1
  end

  # 更新流程对应的错误菜单
  def self.update_menus
    str = ['update: ']
    self.all.each do |r|
      p "...#{r.name}.........................."
      doc = Nokogiri::XML(r.rule_xml)
      doc.css("step").each_with_index do |step, i|
        name = step["name"].to_str
        first_audit = step.at_css('first_audit').to_str
        last_audit = step.at_css('last_audit').to_str
        old_junior = step.at_css('junior').to_str.to_i
        old_senior = step.at_css('senior').to_str.to_i
        junior = Menu.find_by(name: first_audit).try(:id)
        senior = Menu.find_by(name: last_audit).try(:id)
        to_do_id = ToDoList.find_by(id: step.at_css('to_do_id').to_str).try(:name)

        p "#{i+1}. #{name}   to_do_id: #{to_do_id}"
        p "#{old_junior == junior}  #{first_audit}:  junior: #{junior} | old_junior: #{old_junior}"
        p "#{old_senior == senior}  #{last_audit}:  senior: #{senior} | old_senior: #{old_senior}"
        p "=============================================================================="

        unless old_junior == junior
          step.at_css('junior').content = junior
          str << "...#{r.name}....#{first_audit}:  junior: #{junior} | old_junior: #{old_junior}"
        end

        unless old_senior == senior
          step.at_css('senior').content = senior
          str << "...#{r.name}....#{last_audit}:  senior: #{senior} | old_senior: #{old_senior}"
        end
      end
      r.update(rule_xml: doc.to_s)
    end
    str.each{ |e| p e }
    p str.size-1
  end

end
