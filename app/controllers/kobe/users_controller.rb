# -*- encoding : utf-8 -*-
class Kobe::UsersController < KobeController

  before_action :get_user, :only => [:edit, :show, :update, :reset_password, :update_password, :freeze, :save_freeze]
  layout :false, :only => [:show, :edit, :reset_password]


  def edit
    @myform = SingleForm.new(User.xml, @user, { form_id: "user_form", action: kobe_user_path(@user), method: "patch" })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@user, User.xml) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@user) }
  end

  def reset_password
  end

  def update()
    if update_and_write_logs(@user, User.xml)
      redirect_to kobe_departments_path(id: @user.department.id)
    else
      redirect_back_or
    end
  end

  def update_password
    if @user.update(params.require(:user).permit(:password, :password_confirmation))
      write_logs(@user,"重置密码",'重置密码成功')
      tips_get("重置密码成功。")
      redirect_to kobe_departments_path(id: @user.department.id)
    else
      flash_get(@user.errors.full_messages)
      redirect_back_or
    end
  end

  # 冻结
  def freeze
    render partial: '/shared/dialog/opt_liyou', locals: {form_id: 'freeze_user_form', action: save_freeze_kobe_user_path(@user)}
  end

  def save_freeze
    logs = prepare_logs_content(@user,"冻结用户",params[:opt_liyou])
    if @user.change_status_and_write_logs("冻结",logs)
      tips_get("冻结用户成功。")
    else
      flash_get(@user.errors.full_messages)
    end
    redirect_to kobe_departments_path(id: @user.department.id)
  end

  private  

  def get_user
    params[:id] ||= current_user.id
    @user = User.find(params[:id])
  end
end
