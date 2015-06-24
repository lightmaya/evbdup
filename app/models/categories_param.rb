# -*- encoding : utf-8 -*-
class CategoriesParam < XmlColumn
	# belongs_to :category

	def self.xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node name='参数名称' column='name' class='required'/>
	    	<node name='字段名称' column='column' data_type='hidden'/>
	    	<node name='参数类型' column='data_type' data_type='select' class='required' data='#{Dictionary.inputs.data_type}'/>
	    	<node name='参数格式' column='rule' data_type='select' class='required' data='#{Dictionary.inputs.rule}'/>
	    	<node name='选择项' column='data' hint='单选、多选、下拉单选、下拉多选必须填写选择项，以"|"分割'/>
	    	<node name='是否必填' column='is_required' class='required' data_type='radio' data='[[1,"是"],[0,"否"]]'/>
	      <node name='提示' column='hint'/>
	      <node name='占位符' column='placeholder'/>
	    </root>
	  }
	end

	def self.default_xml(who='',options={})
		%Q{
			<?xml version="1.0" encoding="UTF-8"?>
			<root>
			  <node name="品牌" column='brand' class="required"/>
			  <node name="型号" column='model' class="required"/>
			  <node name="版本号" column='version' class="text"/>
			  <node name="计量单位" column='unit' class="required"/>
			  <node name="市场价格" column='market_price' class="required number"/>
			  <node name="中标价格" column='bid_price' class="required number"/>
			  <node name="基本描述" column='summary' class="required"/>
			</root>
		}
	end
end
