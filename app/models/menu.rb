# -*- encoding : utf-8 -*-
class Menu < ActiveRecord::Base
  # has_and_belongs_to_many  :users
  # 树形结构
  has_ancestry :cache_depth => true
  # default_scope -> {order(:ancestry, :sort, :id)}

  has_many :user_menus, :dependent => :destroy
  has_many :users, through: :user_menus

  has_many :task_queues

  scope :by_user_type, ->(user_type) { where("find_in_set('#{user_type}', menus.user_type) > 0") }

	include AboutAncestry
	include AboutStatus
  
  default_value_for :status, 65

  after_save do 
    Setting.where("var like 'user_options_%' or var like 'menus_%'").delete_all if changes["id"].blank? && changes["can_opt_action"].present?
    if changes[:route_path].present?
      users.map{|user| user.cache_menus(true)}
    end
    if changes[:can_opt_action].present?
      users.map{|user| user.cache_option_hash(true)}
    end
  end

	# 中文意思 状态值 标签颜色 进度 
  def self.status_array
    # [["正常", "65", "yellow", 100], ["已删除", "404", "dark", 100]]
    self.get_status_array(["正常", "已删除"])
    # [
    #   ["正常",0,"u",100],
    #   ["已删除",404,"red",0]
    # ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   {
  #     "删除" => { 0 => 404 }
  #   }
  # end

  # 根据action_name 判断obj有没有操作
  def cando(act='')
    ["delete", "destroy"].include?(act) ? self.can_opt?("删除") : false
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  # 	# 列表中不允许出现的
  # 	limited = [404]
  # 	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

  def self.xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node name='parent_id' data_type='hidden'/>
	    	<node name='父节点名称' display='disabled'/>
	      <node name='名称' column='name' class='required'/>
	      <node name='相对路径' column='route_path'/>
        <node name='权限判断' column='can_opt_action' hint='用于cancancan判断用户是否有这个操作 默认read,create,update,update_destroy 也可自定义action 例如：Department|update'/>
	      <node name='排序号' column='sort' class='digits' hint='只能输入数字,数字越小排序越靠前'/>
	      <node name='图标' column='icon'/>
        <node name='显示菜单' column='is_show' data_type='radio' data='[[0,"不显示菜单"],[1,"显示菜单"]]'/>
        <node name='自动获取' column='is_auto' data_type='radio' data='[[0,"不自动获取"],[1,"自动获取"]]'/>
        <node name='弹出页面' column='is_blank' data_type='radio' data='[[0,"不弹出页面"],[1,"弹出页面"]]'/>
        <node name='用户类别' column='user_type' hint='#{Dictionary.manage_user_type}：表示监管用户，#{Department.purchaser.try(:id)}：表示采购用户，#{Department.supplier.try(:id)}：表示供应商，#{Dictionary.audit_user_type}：表示审核用户。例如：1,2,3 或者 7'/>
	    </root>
	  }
	end

  # 显示菜单
  def show_top(arr=[])
    return '' if (self.subtree & arr).blank?
    # 如果有孩子
    if self.has_visible_children? 
      substr = "<ul class=\"dropdown-menu\">"
      self.visible_children.each{|c|substr << c.show_top(arr)}
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

  # 可以显示的孩子菜单
  def visible_children
    self.children.where(is_show:true)
  end

  # 是否有可以显示的孩子菜单
  def has_visible_children?
    self.visible_children.present?
  end

  # 根据can_opt_action找到menu 返回menu的subtree的id数组 can_act="Department|update"
  def self.get_menu_ids(can_act='')
    return [] if can_act.blank?
    menu = self.find_by(can_opt_action: can_act)
    return menu.present? ? menu.subtree.map(&:id) : []
  end

end
