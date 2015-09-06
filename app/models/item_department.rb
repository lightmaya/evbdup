# -*- encoding : utf-8 -*-
class ItemDepartment < ActiveRecord::Base
	belongs_to :department
  belongs_to :item

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "ItemDepartment") }, foreign_key: :obj_id

  include AboutRuleStep

  before_save do 
  	rule = Rule.find_by(yw_type: self.class.to_s)
  	self.rule_id = rule.try(:id)
  	self.rule_step = 'start'
  end

  def self.xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node column='id' data_type='hidden'/>
	      <node name='单位名称' column='name' class='required'/>
	    </root>
	  }
	end

end
