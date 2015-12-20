# -*- encoding : utf-8 -*-
class User < ActiveRecord::Base

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  # validates :email, presence: true, format: { with:VALID_EMAIL_REGEX }#, uniqueness: { case_sensitive: false }
  has_secure_password
  validates :password, presence: true, :on => :create
  validates :login, presence: true, uniqueness: { case_sensitive: false }
  include AboutStatus
  # validates_with MyValidator, on: :update

  belongs_to :department
  has_many :user_menus, :dependent => :destroy
  has_many :menus, through: :user_menus
  has_many :user_categories, :dependent => :destroy
  has_many :categories, through: :user_categories
  has_many :orders
  has_many :yjjy , class_name:'Faq' , foreign_key: 'ask_user_id'
  # 收到的消息
  has_many :msg_users
  # has_many :unread_notifications, -> { where "status=0" }, class_name: "Notification", foreign_key: "receiver_id"
  has_many :bid_projects
  has_many :bid_project_bids

  # 当前用户可用的预算审批单
  has_many :valid_budgets, -> { where(status: self.effective_status) }, class_name: "Budget", foreign_key: "user_id"

  # before_save {self.email = email.downcase}
  before_create :create_remember_token

  default_value_for :status, 65

  after_save do
    self.reset_menus_cache if self.previous_changes["menuids"].present?
  end
  # 为了在Model层使用current_user
  # def self.current
  #   Thread.current[:user]
  # end

  # def self.current=(user)
  #   Thread.current[:user] = user
  # end

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

  # 判断当前用户所在单位是采购单位、供应商还是监管机构
  def user_type
    if self.real_department.is_zgs?
      return Dictionary.manage_user_type
    else
      return self.department.root_id
    end
  end

  def cgr?
    [1,2].include? self.department.root_id
  end

  # 获取当前人的菜单
  # def show_menus
  #   return menus_ul(Menu.to_depth(0))
  # end

  def self.status_array
    # [["正常", "65", "yellow", 100], ["已删除", "404", "dark", 100], ["已冻结", "12", "dark", 100]]
    self.get_status_array(["正常", "已冻结", "已删除"])
    # [
    #   ["正常",0,"u",100],
    #   ["冻结",1,"yellow",100]
    # ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   {
  #     "冻结" => { 0 => 1 },
  #     "恢复" => { 1 => 0 }
  #   }
  # end

  def self.xml(obj, current_u)
    tmp = ''
    if current_u.is_admin
      if current_u.user_type == Dictionary.manage_user_type
        tmp << %Q{
        <node name='是否单位管理员' column='is_admin' data_type='radio' data='[[0,"否"],[1,"是"]]'/>
        }
      end
      tmp << %Q{
        <node name='权限分配' class='tree_checkbox required' json_url='/kobe/shared/user_ztree_json' partner='menuids' json_params='{"id":"#{obj.id}"}' hint='如果没有可选项，请先查看单位状态和用户状态是否正常！'/>
        <node column='menuids' data_type='hidden'/>
        <node name='品目分配' class='tree_checkbox' json_url='/kobe/shared/category_ztree_json' partner='categoryids'/>
        <node column='categoryids' data_type='hidden' hint='如勾选品目，待办事项中只显示勾选的品目的相关信息。'/>
      }
    end
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='用户名' column='login' class='required' display='readonly'/>
        <node name='姓名' column='name' class='required'/>
        <node name='电话' column='tel'/>
        <node name='手机' column='mobile' class='required'/>
        <node name='传真' column='fax'/>
        <node name='职务' column='duty'/>
        <node name='用户类型' column='is_personal' data_type='radio' data='[[0,"单位用户"],[1,"个人用户"]]'/>
        #{tmp}
      </root>
    }
  end

  # 显示菜单
  def show_menus
    str = ""
    Menu.roots.where(is_show: true).each do |menu|
      str << menu.show_top(self.menus.uniq)
    end
    str
  end

  def cache_menus(force = false)
    if force
      Setting.send("menus_#{self.id}=", show_menus)
    else
      Setting.send("menus_#{self.id}=", show_menus) if Setting.send("menus_#{self.id}").blank?
    end
    Setting.send("menus_#{self.id}")
  end

  def desotry_cache_menus
    Setting.send("menus_#{self.id}=", nil)
  end

  def desotry_cache_option_hash
    Setting.send("user_options_#{self.id}=", nil)
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
        rs[a[0]] << "update_#{a[1]}".to_sym unless ["create", "read", "update", "update_destroy", "commit", "show", "print_order", "search", "move", "first_audit", "last_audit", "tongji"].include?(a[1]) || a[1].include?("list")
        if a[1].include?("list_r")
          rs[a[0]] << "list".to_sym
        end
        # 审核
        if ["first_audit", "last_audit"].include?(a[1])
          rs[a[0]] << "audit".to_sym
          rs[a[0]] << "update_audit".to_sym
        end
        rs[a[0]].uniq!
      end
    end
    rs
  end

  def cache_option_hash(force = false)
    if force
      Setting.send("user_options_#{self.id}=", can_option_hash)
    else
      Setting.send("user_options_#{self.id}=", can_option_hash) if Setting.send("user_options_#{self.id}").blank?
    end
    Setting.send("user_options_#{self.id}")
  end

  # 判断用户是否有某个操作
  # def has_option?(option_key='',action='')
  #   return false if option_key.blank? || action.blank?
  #   opt = self.can_option_hash[option_key]
  #   return opt.present? && opt.include?(action.to_sym)
  # end

  # 重置权限缓存
  def reset_menus_cache
    self.cache_menus(true)
    self.cache_option_hash(true)
  end

  # 自动获取操作权限
  def set_auto_menu
    self.menu_ids = self.get_auto_menus.map(&:id)
    self.reset_menus_cache
  end

  # 根据user_type判断用户的权限
  # 如果单位不是正常状态的 只能有is_auto=true的权限
  def get_auto_menus
    # 用户状态是冻结 或者单位状态是冻结、已删除的 没有任何权限
    if self.status == 12 || [12, 404].include?(self.department.status)
      return []
    else
      # 只有总公司或者分公司的人才有审核权限
      ms = if self.real_department.is_zgs? || self.real_department.is_fgs?
        Menu.status_not_in(404).where("find_in_set('#{self.user_type}', menus.user_type) > 0 or menus.user_type = '#{Dictionary.audit_user_type}'")
      else
        Menu.status_not_in(404).by_user_type(self.user_type)
      end
      return Department.effective_status.include?(self.department.status) ? ms : ms.where(is_auto: true)
    end
  end

  # 待办事项的条件
  def to_do_condition
    ["(user_id = ? or (user_id is null and menu_id in (?))) and dep_id = ?", self.id, self.menu_ids, self.real_department.id]
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
  def cando(act='',current_u)
    cdt = current_u.is_admin || current_u.user_type == Dictionary.manage_user_type
    case act
    when "show", "index", "only_show_info", "only_show_logs"
      true
    when "edit", "update", "reset_password", "update_reset_password"
      self.class.edit_status.include?(self.status) && self.class.edit_status.include?(self.department.status) && cdt || self.id == current_u.id
    when "recover", "update_recover"
      self.can_opt?("恢复") && cdt
    when "freeze", "update_freeze"
      self.can_opt?("冻结") && cdt
    else false
    end
  end

  # 用户的真实单位
  def real_department
    self.department.real_dep
  end

  # 该用户真实的单位code
  def real_dep_code
    self.department.real_ancestry
  end

  # 参与的竞价报价
  def bid_project_bid(bid_project)
    bpb = BidProjectBid.find_or_initialize_by(user_id: self.id, bid_project_id: bid_project.id)
    if bpb.new_record?
      bpb.com_name = self.real_department.name
      bpb.add = self.department.address
      bpb.username = self.name
      bpb.tel = self.tel
      bpb.mobile = self.mobile
    end
    bpb
  end

  # 参与的竞价产品明细报价
  def bid_item_bids(bid_project)
    BidItemBid.where(user_id: self.id, bid_project_id: bid_project.id)
  end

  # 联系方式
  def tel_and_mobile
    [self.mobile, self.tel].select{|i| i.present?}.join(" / ")
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
