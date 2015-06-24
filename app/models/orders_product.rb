# -*- encoding : utf-8 -*-
class OrdersProduct < ActiveRecord::Base
	belongs_to :order
	
	# 从表的XML加ID是为了修改的时候能找到记录
	def self.xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node column='id' data_type='hidden'/>
	    	<node column='category_code' data_type='hidden'/>
	    	<node name='品目' class='tree_radio required' json_url='/json/areas' partner='category_code'/>
	    	<node name='品牌' column='brand' class='required'/>
	    	<node name='型号' column='model' class='required'/>
	    	<node name='版本号' column='version' hint='颜色、规格等有代表性的信息，可以不填。'/>
	      <node name='市场单价（元）' column='market_price' class='required number'/>
	      <node name='入围单价（元）' column='bid_price' class='number'/>
	      <node name='成交单价（元）' column='price' class='required number'/>
	      <node name='数量' column='quantity' class='required number'/>
	      <node name='单位' class='zip' column='unit' class='required'/>
	      <node name='小计（元）' column='total' class='required number'/>
	      <node name='备注' column='summary' data_type='textarea' class='maxlength_800' placeholder='不超过800字'/>
	    </root>
	  }
	end
end
