# -*- encoding : utf-8 -*-
class User < ActiveRecord::Base
  # before_save {self.email = email.downcase}
  before_create :create_remember_token

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  # validates :email, presence: true, format: { with:VALID_EMAIL_REGEX }#, uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, length: { in: 6..20 }, :on => :create
  validates :login, presence: true, length: { in: 6..20 }, uniqueness: { case_sensitive: false }

  belongs_to :department
  has_many :user_menus, :dependent => :destroy
  has_many :menus, through: :user_menus
  # 收到的消息
  has_many :unread_notifications, -> { where "status=0" }, class_name: "Notification", foreign_key: "receiver_id"  

  include AboutStatus
  validates_with MyValidator, on: :update

  # 为了在Model层使用current_user
  def self.current
    Thread.current[:user]
  end
  
  def self.current=(user)
    Thread.current[:user] = user
  end

  # 是否超级管理员,超级管理员不留操作痕迹
  def admin?
    # self.roles.map(&:name).include?("系统管理员")
  end

  def User.new_remember_token
    SecureRandom.urlsafe_base64
  end

  def User.encrypt(token)
    Digest::SHA1.hexdigest(token.to_s)
  end

  # 获取当前人的菜单
  def show_menus
    return menus_ul(Menu.to_depth(0))
  end

  def self.status_array
    [
      ["正常",0,"u",100], 
      ["冻结",1,"yellow",100], 
      ["已删除",98,"red",100]
    ]
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='用户名' column='login' class='required rangelength_6_20' display='readonly'/>
        <node name='电子邮箱' column='email' class='required email'/>
        <node name='姓名' column='name' class='required'/>
        <node name='电话' column='tel'/>
        <node name='手机' column='mobile' class='required'/>
        <node name='传真' column='fax'/>
        <node name='职务' column='duty'/>
        <node name='权限分配' class='tree_checkbox required' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"Menu"}' partner='menuids'/>
        <node column='menuids' data_type='hidden'/>
      </root>
    }
  end

  def cando_list(action='')
    arr = [] 
    dialog = "#opt_dialog"
    # 详细
    title = self.class.icon_action("详细")
    arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '/kobe/users/#{self.id}', '#{dialog}') }]
    # 修改
    if [0,404].include?(self.status)
      arr << [self.class.icon_action("修改"), "javascript:void(0)", onClick: "show_content('/kobe/users/#{self.id}/edit','#show_ztree_content #ztree_content')"]
    end
    # 重置密码
    if [0,404].include?(self.status)
      title = self.class.icon_action("重置密码")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '/kobe/users/#{self.id}/reset_password', '#{dialog}') }]
    end
    # 冻结
    if [0,404].include?(self.status)
      title = self.class.icon_action("冻结")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '/kobe/users/#{self.id}/freeze', '#{dialog}') }]
    end
    return arr
  end
  
  # 显示菜单
  def show_menus
    str = ""
    Menu.roots.each do |menu|
      str << menu.show_top(self.menus.uniq)
    end
    str
  end

  private

  def create_remember_token
    self.remember_token=User.encrypt(User.new_remember_token)
  end

  # 在layout中展开菜单menu
  def menus_ul(mymenus = [])
    str = "<ul class='nav nav-stacked'>"
    mymenus.each{|m| str << menus_li(m) }
    str << "</ul>"
    return str
  end

  def menus_li(menu)
    if menu.icon.blank?
      case menu.depth
      when 0
        menu.icon = "icon-caret-right"  
      when 1
        menu.icon = "icon-chevron-right"
      else
        menu.icon = "icon-angle-right"
      end
    end
    unless menu.has_children?
      str = "<li><a href='#{menu.route_path}'><i class='#{menu.icon}'></i><span>#{menu.name}</span></a></li>"
    else
      str = "<li><a class='dropdown-collapse' href='#{menu.route_path}'><i class='#{menu.icon}'></i><span>#{menu.name}</span><i class='icon-angle-down angle-down'></i></a>"
      str << menus_ul(menu.children)
      str << "</li>"
    end
    return str
  end

end
