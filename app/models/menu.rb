# -*- encoding : utf-8 -*-
class Menu < ActiveRecord::Base
  has_and_belongs_to_many  :users
  # 树形结构
  has_ancestry :cache_depth => true
  default_scope -> {order(:ancestry, :sort, :id)}

	include AboutAncestry

  def self.xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node name='parent_id' data_type='hidden'/>
	    	<node name='父节点名称' display='disabled'/>
	      <node name='名称' column='name' rules='{required:true}'/>
	      <node name='相对路径' column='route_path' rules='{required:true}'/>
	      <node name='排序号' column='sort' rules='{required:true, digits:true}' hint='只能输入数字'/>
	      <node name='状态' column='status' data_type='radio' data='[[1,"有效"],[0,"无效"]]' rules='{required:true}'/>
	      <node name='图标' column='icon' rules='{required:true}'/>
	    </root>
	  }
	end

end
