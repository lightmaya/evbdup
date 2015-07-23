# -*- encoding : utf-8 -*-
class Menu < ActiveRecord::Base
  # has_and_belongs_to_many  :users
  # 树形结构
  has_ancestry :cache_depth => true
  default_scope -> {order(:ancestry, :sort, :id)}

  has_many :role_menus, :dependent => :destroy
  has_many :roles, through: :role_menus
  has_many :users, through: :roles

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
	      <node name='相对路径' column='route_path' class='required'/>
	      <node name='排序号' column='sort' class='digits' hint='只能输入数字,数字越小排序越靠前'/>
	      <node name='图标' column='icon'/>
	    </root>
	  }
	end

  # 显示菜单
  def show_top(arr=[])
    return '' if (self.subtree & arr).blank?
    # 如果有孩子
    if self.has_children? 
      substr = "<ul class=\"dropdown-menu\">"
      self.children.each{|c|substr << c.show_top(arr)}
      substr << "</ul>"
      # 如果是根节点
      unless self.root?
        str = %Q|
        <li class="dropdown-submenu">
          <a href="javascript:void(0);">#{self.name}</a>
          #{substr}
        </li>|
      else
        str = %Q|
        <li class="dropdown">
          <a href="javascript:void(0);" class="dropdown-toggle" data-toggle="dropdown"><i class="fa #{self.icon}"></i> #{self.name}</a>
          #{substr}
        </li>|
      end
    # 如果没有孩子直接显示
    else
        return "<li><a href=\"#{self.route_path}\">#{self.name}</a></li>"
    end
    return str
  end

end
