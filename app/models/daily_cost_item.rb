# -*- encoding : utf-8 -*-
class DailyCostItem < ActiveRecord::Base
	belongs_to :daily_cost
	belongs_to :daily_categroy
	before_save do
		ca = self.daily_category_id.present? ? DailyCategory.find_by(id: self.daily_category_id) : DailyCategory.find_by(name: self.category_name)
		self.category_code = ca.ancestry if ca.present?
	end

		# 从表的XML加ID是为了修改的时候能找到记录
	def self.xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node column='id' data_type='hidden'/>
	    	<node column='daily_category_id' data_type='hidden'/>
	    	<node name='报销类别' column='category_name' class='tree_radio required' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"DailyCategory"}' partner='daily_category_id'/>
	    	<node name='项目' column='daily_xm' class='required'/>
	      <node name='金额' column='total' class='required number'/>
	      <node name='备注' column='summary' data_type='textarea' class='maxlength_800' placeholder='不超过800字'/>
	    </root>
	  }
	end
end
