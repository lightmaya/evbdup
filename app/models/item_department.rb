# -*- encoding : utf-8 -*-
class ItemDepartment < ActiveRecord::Base
	belongs_to :department
  belongs_to :item

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
