# -*- encoding : utf-8 -*-
class RuleStep < XmlColumn

	def self.keys
		%w(name dep junior senior inflow outflow first_audit last_audit to_do_id)
	end

	def self.xml(who='',options={})
		to_do_data = ToDoList.status_not_in(404).map{ |e| [e.id.to_s, e.name] }
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node name='名称' column='name' class='required' hint='例如：总公司审核'/>
	    	<node name='初审权限' column='first_audit' class='tree_checkbox required' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"Menu"}' partner='junior'/>
        <node column='junior' data_type='hidden'/>
        <node name='终审权限' column='last_audit' class='tree_checkbox required' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"Menu"}' partner='senior'/>
        <node column='senior' data_type='hidden'/>
        <node name='待办事项显示名称' column='to_do_id' class='required' data_type='select' data='#{to_do_data}' hint='例如：审核定点采购项目'/>
	      <node name='审核单位' column='dep' data_type='textarea' class='required' hint='例如：self.real_ancestry_level(2)'/>
	      <node name='执行条件' column='inflow' data_type='textarea' class='required' hint='例如：self.total > 3000'/>
	      <node name='跳过条件' column='outflow' data_type='textarea' class='required' hint='例如：self.status == 404'/>
	    </root>
	  }
	end

	# 生成规则
	# <step name="总公司审核">
  #   <first_audit>单位初审</first_audit>
  #   <junior>19</junior>
  #   <last_audit>单位终审</last_audit>
  #   <senior>20</senior>
  #   <to_do_id>1</to_do_id>
  #   <dep>Department.find(2).children.first.real_ancestry_level(2)</dep>
  #   <inflow>self.status == 2</inflow>
  #   <outflow>self.status == 404</outflow>
  # </step>
	def self.create_rule_xml(params='')
		return '' if params.blank?
		params_arr = params.require(self.to_s.tableize.to_sym)
		column_arr = Nokogiri::XML(self.xml).xpath("/root/node[@column!='name']").map{ |node| node.attributes["column"].to_str }
		doc = Nokogiri::XML::Document.new
    doc.encoding = "UTF-8"
    doc << "<root>"
    params_arr["name"].keys.each do |i|
			step = doc.root.add_child("<step>").first
			step["name"] = params_arr["name"][i] if params_arr["name"][i].present?
	    column_arr.each do |column|
	    	next if params_arr[column].blank? || params_arr[column][i].blank?
	    	node = Nokogiri::XML::Node.new column, step
	    	node.content = params_arr[column][i]
	    	step.add_child(node)
	    end
	  end
	  return doc.to_s
	end

end
