# -*- encoding : utf-8 -*-
class Msg < ActiveRecord::Base
  has_many :users, class_name: "MsgUser"
  belongs_to :author, class_name: "User", foreign_key: "user_id"

  include AboutStatus

  default_value_for :status, 0

  after_save do
    if self.status == 2 && users.count == 0
      # 后台异步插入接收人数据
      Rufus::Scheduler.new.in "1s" do
        link_users
        ActiveRecord::Base.clear_active_connections!
      end
    end
  end

   # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  #   # 列表中不允许出现的
  #   # limited = [404]
  #   limited = []
  #   arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

  def link_users
    return if users.count > 0
    if self.send_type == 1
      self.send_tos.split.each do |login|
        if user = User.find_by_login(login)
          ::MsgUser.find_or_create_by(msg_id: self.id, user_id: user.id)
        end
      end
    elsif self.send_type == 0
      self.send_tos.split.each do |dep_id|
        if d = Department.find_by_id(dep_id)
          d.subtree.map(&:users).flatten.uniq.each do |user|
            ::MsgUser.find_or_create_by(msg_id: self.id, user_id: user.id)
          end
        end
      end
    end
  end

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [["暂存", "0", "orange", 10], ["已发布", "16", "yellow", 40], ["已删除", "404", "dark", 100]]
    self.get_status_array(["暂存", "已发布", "已删除"])
    # [
    #   ["暂存", 0, "orange", 50],
    #   ["已发布", 2, "u", 100]
    # ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   {
  #     "发布" => { 0 => 2 },
  #     "删除" => { 0 => 404 }
  #   }
  # end

  # 根据action_name 判断obj有没有操作
  def cando(act='', user)
    return false if user.try(:id) != self.user_id
    case act
    when "update", "edit"
      self.class.edit_status.include?(self.status)
    when "commit"
      self.can_opt?("提交")
    when "delete", "destroy"
      self.can_opt?("删除")
    else
      false
    end
  end

  # 获取提示信息 用于1.注册完成时提交的提示信息、2.登录后验证个人信息是否完整
  # def get_tips
  #   msg = []
  #   if [0].include?(self.status)
  #     msg << "请填写内容" if self.content.blank?
  #     msg << "请填写标题" if self.title.blank?
  #     msg << "请填写接收人类型" if self.send_tos.blank?
  #     msg << "请填写接收人" if self.send_type.blank?
  #   end
  #   return msg
  # end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='标题' column='title' class='required'/>
        <node name='作者' column='user_name' class='required'/>
        <node name='状态' column='status' class='required' data_type='radio'  data='[[0, "暂存"],[2, "直接发送"]]' />
        <node name='接收人类型'  data_type='radio'  data='#{Dictionary.send_types}' column='send_type' class='required'/>
        <node name='具体接收人' column='send_tos' class='required' data_type='textarea' hint="接收人类型为单位请填写单位ID，个人请填写登录名。多接收人用空格隔开。" />
        <node name='内容' column='content' class='required' data_type='richtext' style='width:100%;height:300px;' />
      </root>
    }
  end

  def content_html
    "<h3 class=\"f10\">作者：#{self.user_name} 时间：#{self.created_at}</h3>" +
    "<hr/>" +
    "#{self.content}".html_safe
  end

  def self.f(title, content, send_type, send_tos)
    if msg = Msg.create(title: title, content: content, send_type: send_type, send_tos: send_tos)
      Rufus::Scheduler.new.in "1s" do
        msg.link_users
        ActiveRecord::Base.clear_active_connections!
      end
    end
  end

end
