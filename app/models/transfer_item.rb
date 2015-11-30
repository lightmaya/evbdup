 # -*- encoding : utf-8 -*-
class TransferItem < ActiveRecord::Base
	belongs_to :transfer
	belongs_to :category



	before_save do
		ca = self.category_id.present? ? Category.find_by(id: self.category_id) : Category.find_by(name: self.category_name)
		self.category_code = ca.ancestry if ca.present?
  end

	# 从表的XML加ID是为了修改的时候能找到记录
	def self.xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node column='id' data_type='hidden'/>
	    	<node column='category_id' data_type='hidden'/>
	    	<node name='设备名称' column='category_name' class='tree_radio required' json_url='/kobe/shared/category_ztree_json' partner='category_id'/>
	    	<node name='型号' class='required'/>
	    	<node name='数量' column='num' class='required number'/>
	    	<node name='计量单位' column='unit' data_type='select' data="['台','辆','套']"/>
	    	<node name='生产厂家'  class='required'/>
	    	<node name='生产年份'  class='date_select required dateISO'/>
	    	<node name='购入日期'  class='date_select required dateISO'/>
	      <node name='资产原值' column='original_price' class='required number'/>
	      <node name='资产净值' column='net_price' class='required number'/>
	      <node name='转让资金'  column='transfer_price' class='required number'/>
	      <node name='设备状态' column='product_status' data_type='select' data="[[0,'完好可使用'],[1,'需要维修'], [2,'提供配件']]" />
	      <node name='配件情况' data_type='select' data="['配件齐全','有部分配件', '无配件']" />
	      <node name='运费'  data_type='select' data="['接收方支付','转让方支付']"/>
	      <node name='技术规格或产品说明' column='description' data_type='textarea' class='maxlength_800' placeholder='不超过800字'/>
	      <node name='备注' column='summary' data_type='textarea' class='maxlength_800' placeholder='不超过800字'/>
	    </root>
	  }
	end

end
