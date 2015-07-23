# -*- encoding : utf-8 -*-
class Role < ActiveRecord::Base
  # has_and_belongs_to_many  :users
  # has_and_belongs_to_many  :permissions
  # 树形结构
  has_ancestry :cache_depth => true
  default_scope -> {order(:ancestry, :sort, :id)}

  has_many :role_menus, :dependent => :destroy
  has_many :menus, through: :role_menus
  has_many :user_roles, :dependent => :destroy
  has_many :users, through: :user_roles

  include AboutAncestry
  include AboutStatus

	# 中文意思 状态值 标签颜色 进度 
  def self.status_array
    [
      ["正常",0,"u",100],
      ["已删除",404,"red",0]
    ]
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	limited = [404]
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  def self.xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node name='parent_id' data_type='hidden'/>
	    	<node name='父节点名称' display='disabled'/>
	      <node name='名称' column='name' class='required'/>
	      <node name='权限分配' class='tree_checkbox required' json_url='/json/menus' partner='menuids'/>
	      <node column='menuids' data_type='hidden'/>
	      <node name='排序号' column='sort' class='digits' hint='只能输入数字,数字越小排序越靠前'/>
	    </root>
	  }
	end
  private

end
