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

  has_many :user_categories, :dependent => :destroy
  has_many :categories, through: :user_categories

  has_many :orders
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
    false
    # self.roles.map(&:name).include?("系统管理员")
  end

  def User.new_remember_token
    SecureRandom.urlsafe_base64
  end

  def User.encrypt(token)
    Digest::SHA1.hexdigest(token.to_s)
  end

  # 获取当前人的菜单
  # def show_menus
  #   return menus_ul(Menu.to_depth(0))
  # end

  def self.status_array
    [
      ["正常",0,"u",100], 
      ["冻结",1,"yellow",100]
    ]
  end

  # 根据不同操作 改变状态
  def change_status_hash
    {
      "冻结" => { "正常" => "冻结" },
      "恢复" => { "冻结" => "正常" }
    }
  end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='用户名' column='login' class='required rangelength_6_20' display='readonly'/>
        <node name='姓名' column='name' class='required'/>
        <node name='电话' column='tel'/>
        <node name='手机' column='mobile' class='required'/>
        <node name='传真' column='fax'/>
        <node name='职务' column='duty'/>
        <node name='是否单位管理员' column='is_admin' data_type='radio' data='[[0,"否"],[1,"是"]]'/>
        <node name='用户类型' column='user_type' data_type='radio' data='[[0,"单位用户"],[1,"个人用户"]]'/>
        <node name='权限分配' class='tree_checkbox required' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"Menu"}' partner='menuids'/>
        <node column='menuids' data_type='hidden'/>
        <node name='品目分配' class='tree_checkbox' json_url='/kobe/shared/category_ztree_json' partner='categoryids'/>
        <node column='categoryids' data_type='hidden'/>
      </root>
    }
  end

  # 显示菜单
  def show_menus
    str = ""
    Menu.roots.each do |menu|
      str << menu.show_top(self.menus.uniq)
    end
    str
  end

  # 返回用户的所有操作 用于cancancan {"Department"=> [:create, :read, :update, :update_destroy, :freeze, :update_freeze], "Menu"=>[:create, :read, :update]}
  # 如果是管理员增加一个admin的操作 有admin的可以对别人的订单进行操作
  # menu.can_opt_action = Department|create
  def can_option_hash
    arr = []
    self.menus.each do |m|
      arr << m.can_opt_action if m.can_opt_action.present?
      arr |= m.ancestors.where("can_opt_action is not null and can_opt_action != ''").map(&:can_opt_action)
    end
    rs = {}
    arr.uniq.each do |e| # e = Department|create
      next if e.blank?
      a = e.split("|") 
      if a.length == 2
        rs[a[0]] = [] unless rs.key?(a[0])
        rs[a[0]] << a[1].to_sym
        rs[a[0]] << "update_#{a[1]}".to_sym unless ["create", "read", "update", "update_destroy", "search", "move", "first_audit", "last_audit"].include?(a[1])
        # 审核
        if ["first_audit", "last_audit"].include?(a[1])
          rs[a[0]] << "audit".to_sym
          rs[a[0]] << "update_audit".to_sym
        end
        rs[a[0]].uniq!
      end
    end
    return rs
  end

  # 判断用户是否有某个操作
  # def has_option?(option_key='',action='')
  #   return false if option_key.blank? || action.blank?
  #   opt = self.can_option_hash[option_key]
  #   return opt.present? && opt.include?(action.to_sym)
  # end

  # 自动获取操作权限
  def set_auto_menu
    self.menu_ids = Menu.where(is_auto: true).map(&:id)
  end

  # 待办事项的条件
  def to_do_condition
    ["(user_id = ? or (user_id is null and menu_id in (?))) and dep_id = ?", self.id, self.menu_ids, self.department.real_dep.id]
  end

  # 待办事项 每一个待办事项有多少个 用于列表显示
  # 用select不用count是因为页面显示需要用到task_queue.to_do_list 而count只返回｛to_do_list_id: 3｝
  def to_do_list
    TaskQueue.where(self.to_do_condition).select("to_do_list_id,count(id) as num").group(:to_do_list_id)
  end

  # 该用户的所有待办事项个数
  def to_do_count
    TaskQueue.where(self.to_do_condition).count
  end

  # 该用户的所有待办事项
  def to_do_all
    TaskQueue.where(self.to_do_condition)
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='')
    case act
    when "show", "index", "only_show_info", "only_show_logs" then true
    when "edit", "update", "reset_password", "update_reset_password" then [0,1,3].include?(self.department.status) && self.status == 0
    when "recover", "update_recover" then [0,1,3].include?(self.department.status) && self.can_opt?("恢复")
    when "freeze", "update_freeze" then [0,1,3].include?(self.department.status) && self.can_opt?("冻结")
    else false
    end
  end

  private

  def create_remember_token
    self.remember_token=User.encrypt(User.new_remember_token)
  end

  # 在layout中展开菜单menu
  # def menus_ul(mymenus = [])
  #   str = "<ul class='nav nav-stacked'>"
  #   mymenus.each{|m| str << menus_li(m) }
  #   str << "</ul>"
  #   return str
  # end

  # def menus_li(menu)
  #   if menu.icon.blank?
  #     case menu.depth
  #     when 0
  #       menu.icon = "icon-caret-right"  
  #     when 1
  #       menu.icon = "icon-chevron-right"
  #     else
  #       menu.icon = "icon-angle-right"
  #     end
  #   end
  #   unless menu.has_children?
  #     str = "<li><a href='#{menu.route_path}'><i class='#{menu.icon}'></i><span>#{menu.name}</span></a></li>"
  #   else
  #     str = "<li><a class='dropdown-collapse' href='#{menu.route_path}'><i class='#{menu.icon}'></i><span>#{menu.name}</span><i class='icon-angle-down angle-down'></i></a>"
  #     str << menus_ul(menu.children)
  #     str << "</li>"
  #   end
  #   return str
  # end

end
