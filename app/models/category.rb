# -*- encoding : utf-8 -*-
class Category < ActiveRecord::Base
	has_many :products
  validates_with MyValidator

  include AboutStatus
  include AboutAncestry

  def self.xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node name='parent_id' data_type='hidden'/>
	    	<node name='品目名称' column='name' class='required' rules='{ remote: { url:"/kobe/categories/valid_name", type:"post" }}'/>
	    </root>
	  }
	end

	# 中文意思 状态值 标签颜色 进度 
	def self.status_array
		[
	    ["正常",0,"u",100],
	    ["冻结",1,"yellow",0],
	    ["已删除",404,"red",100]
    ]
  end
end
