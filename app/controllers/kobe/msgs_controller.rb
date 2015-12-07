# -*- encoding : utf-8 -*-
class Kobe::MsgsController < KobeController
  before_filter :check_send_tos, :only => ["create", "update"]

  # 发送的短消息
  def index
    params[:q][:user_id_eq] = current_user.id unless current_user.admin?
    @q = Msg.where(get_conditions("msgs")).ransack(params[:q]) 
    @msgs = @q.result.includes([:author]).page params[:page]
  end

  # 收到的短消息
  def list
    @q = current_user.msg_users.ransack(params[:q])
    @msg_users = @q.result.includes([:msg]).page params[:page]
  end

  def read_msg
    render :json => {"success" => MsgUser.find_by_id(params[:msg_id]).try(:read!)}
  end

  def show
    MsgUser.find_by(user_id: current_user.id, msg_id: @msg.id).try(:read!)
    render layout: false
  end

  # 获取审核的menu_ids
  def get_audit_menu_ids
    @menu_ids = Menu.get_menu_ids("Msg|list")
  end

  # 提交
  def commit
    @msg.change_status_and_write_logs("提交", stateless_logs("提交", "提交成功！", false))
    Rufus::Scheduler.new.in "1s" do
      @msg.link_users
      ActiveRecord::Base.clear_active_connections!
    end
    tips_get("提交成功！")
    redirect_back_or
  end

  def new
    @msg.user_name = current_user.name 
    @myform = SingleForm.new(Msg.xml, @msg, 
      { form_id: "msg_form", action: kobe_msgs_path,
        title: '<i class="fa fa-pencil-square-o"></i> 新建短消息', grid: 2  
      })
  end

  def edit
    @myform = SingleForm.new(Msg.xml, @msg, { form_id: "msg_form", action: kobe_msg_path(@msg), method: "patch", grid: 2 })
  end

  def create
    msg = create_and_write_logs(Msg, Msg.xml)
    redirect_to kobe_msgs_path
  end

  def update
    update_and_write_logs(@msg, Msg.xml)
    redirect_to kobe_msgs_path
  end

  # 批处理
  def batch_task
    render :text => params[:grid].to_s
  end

    # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_msg_form', action: kobe_msg_path(@msg), method: 'delete' }
  end

  def destroy
    @msg.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_msgs_path
  end

  private  
    # 检查接收人是否存在
    def check_send_tos
      succ = false

      if params[:msgs][:send_type] == "1"
        succ = params[:msgs][:send_tos].split.all?{|login| User.find_by_login(login).present? }
      elsif params[:msgs][:send_type] == "0"
        
        succ = params[:msgs][:send_tos].split.all?{|dep_id| Department.find_by_id(dep_id).present? }
      end
      unless succ
        flash_get("具体接受人中有不存在的单位或个人，请检查")
        return redirect_to :back 
      end
    end
end
