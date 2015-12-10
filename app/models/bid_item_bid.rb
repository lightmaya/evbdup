# -*- encoding : utf-8 -*-
class BidItemBid < ActiveRecord::Base
	belongs_to :bid_project
	belongs_to :bid_item
	belongs_to :user
	belongs_to :bid_project_bid

	# 从表的XML加ID是为了修改的时候能找到记录
	def self.xml(who = '', options = {})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node column='id' data_type='hidden' />
	    	<node column='bid_project_id' data_type='hidden' />
	    	<node column='bid_item_id' data_type='hidden' />
	    	<node name='品目' column='category_name' display="readonly" class='required' delegate='bid_item' />
	    	<node name='参考品牌' column='brand_name' class='required' if="obj.bid_item.can_other==0|display=readonly" />
	    	<node name='参考型号' column='xh' class='required' if="obj.bid_item.can_other==0|display=readonly" />
	      <node name='采购数量' column='num' class='required number' display="readonly" delegate='bid_item' />
	      <node name='单价' column='price' class='required number' />
	      <node name='总价' column='total' class='required number' display="readonly" />
	      <node name='计量单位' column='unit' class='required' display="readonly" delegate='bid_item' />
	      <node name='是否允许投报其他型号的产品' column='can_other' class='required' display="readonly" data='#{Dictionary.yes_or_no}' data_type='radio'  delegate='bid_item'/>
	      <node name='技术指标和服务要求' column='req' data_type='textarea' class='maxlength_800' if="obj.bid_item.can_other==0|display=readonly" placeholder='不超过800字'/>
	      <node name='备注' column='remark' data_type='textarea' if="obj.bid_item.can_other==0|display=readonly" class='maxlength_800' placeholder='不超过800字'/>
	    </root>
	  }
	end
end
