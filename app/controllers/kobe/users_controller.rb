# -*- encoding : utf-8 -*-
class Kobe::UsersController < KobeController

  before_action :get_user
  layout :false, :only => [:show, :edit, :reset_password]

  load_and_authorize_resource 

  def index
    @left_bar_arr = []
    @left_bar_arr << { url: only_show_info_kobe_user_path(@user), icon: "fa-user", title: "查看用户信息" } if current_user.has_option?("User", :read)
    @left_bar_arr << { url: edit_kobe_user_path(@user), icon: "fa-pencil", title: "修改用户信息" } if current_user.has_option?("User", :update)
    @left_bar_arr << { url: reset_password_kobe_user_path(@user), icon: "fa-paypal", title: "重置密码" } if current_user.has_option?("User", :reset_password)
    @left_bar_arr << { url: only_show_logs_kobe_user_path(@user), icon: "fa-history", title: "查看日志" } if current_user.has_option?("User", :read)
  end

  def edit
    @myform = SingleForm.new(User.xml, @user, { form_id: "user_form", action: kobe_user_path(@user), method: "patch", grid: 2 })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@user, User.xml) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@user) }
  end

  def only_show_info
    render :text => show_obj_info(@user, User.xml).html_safe
  end

  def only_show_logs
    render :text => show_logs(@user).html_safe
  end

  def reset_password
  end

  def update
    if update_and_write_logs(@user, User.xml)
      @user.menu_ids = @user.menuids.split(",")
      @user.category_ids = @user.categoryids.split(",") if @user.categoryids.present?
      redirect_to kobe_departments_path(id: @user.department.id)
    else
      redirect_back_or
    end
  end

  def update_reset_password
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
    cannot_do_tips unless @user.can_opt?("冻结")
    render partial: '/shared/dialog/opt_liyou', locals: {form_id: 'freeze_user_form', action: update_freeze_kobe_user_path(@user)}
  end

  def update_freeze
    logs = stateless_logs("冻结用户", params[:opt_liyou], false)
    @user.change_status_and_write_logs("冻结",logs)
    tips_get("冻结用户成功。")
    redirect_to kobe_departments_path(id: @user.department.id)
  end

  # 恢复
  def recover
    cannot_do_tips unless @user.can_opt?("恢复")
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'recover_user_form', action: update_recover_kobe_user_path(@user) }
  end

  def update_recover
    @user.change_status_and_write_logs("恢复", stateless_logs("恢复",params[:opt_liyou],false))
    tips_get("恢复用户成功。")
    redirect_to kobe_departments_path(id: @user.department.id)
  end

  private  

  def get_user
    @user = current_user
    if current_user.has_option?("User", :admin)
      @user = User.find_by(id: params[:id]) if params[:id].present?
    else
      if current_user.is_admin && params[:id].present?
        current_user.department.subtree.each do |d|
          u = d.users.find_by(id: params[:id])
          @user = u if u.present?
        end
      end
    end

    cannot_do_tips if @user.blank?
  end
end
