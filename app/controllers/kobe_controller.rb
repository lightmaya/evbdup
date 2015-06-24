# -*- encoding : utf-8 -*-
class KobeController < ApplicationController
  before_action :request_signed_in!
  before_action :init_themes

  def index
    # @user = current_user
    # UserMailer.registration_confirmation(@user).deliver
    # render :text => "sdfsdfsdf"
  end

  def test
    Setting.audit_money = {"汽车采购" => 180000, "办公小额" => 3000}
    @tmp = "
    <p>读取字典数据（静态配置信息）：#{Dictionary.company_name}</p>
    <br/>
    <p>读取设置数据（动态配置信息）：#{Setting.audit_money["汽车采购"].to_s}</p>
    <br/>
    <p>默认时间格式：#{Time.new.to_s}</p>
    <br/>
    <p>中文时间格式：#{Time.new.to_s(:cn_time)}</p>"
    @city = Area.find(1)
  end

  # 类模型的json格式，tree_select使用
  def obj_class_json
    obj_class = params[:obj_class]
    if obj_class.blank?
      str = '[]'
    else
      begin
        str = obj_class.constantize.get_json(params[:name])
      rescue 
        str = '[]'
      end
    end
    return render :json => str
  end
  
  # 以下是公用方法
  protected

  # 树节点移动
  def ztree_move(obj_class)
    render :text => obj_class.ztree_move_node(params[:sourceId],params[:targetId],params[:moveType],params[:isCopy])
  end

  # 以下是私有方法
  private 
  
  # 准备主界面的素材 ---- #未读短信息
  def init_themes
    @unread_notifications = current_user.unread_notifications
    @suggestion_form = SingleForm.new(Suggestion.xml,Suggestion.new,{upload_files: true, grid: 1, form_id: "suggestion_form", action: kobe_suggestions_path})
  end

  # 获取列表的查询条件,arr应该是一个二维数组,类似于[["name = ? ", "xxx"],["user_id = ? ",11]]
  def get_conditions(arr=[])
    # 列表标题栏筛选的条件
    filter_arr = head_filter
    arr = arr | filter_arr
    unless arr.blank?
      keys = []
      arr.each{|a| 
        keys << a.delete_at(0)
      }
      return arr.flatten!.unshift(keys.join(" and "))
    else 
      return []
    end
  end

  # 列表标题栏的筛选
  def head_filter
    arr = []
    unless params[:status_filter].blank? || params[:status_filter] == "all"
      arr << ["status = ?", params[:status_filter].to_i]
    end 
    unless params[:date_filter].blank? || params[:date_filter] == "all"
      arr << ["created_at >= ?", translate_cn_date(params[:date_filter])]
    end
    return arr
  end

  # 翻译日期,数据来源参照kobe_helper的date_filter方法
  def translate_cn_date(d)
    case d
    when "3m"
      return Time.now.midnight - 3.month
    when "6m"
      return Time.now.midnight - 6.month
    when "1y"
      return Time.now.midnight - 1.year
    when "ty"
      return Time.now.beginning_of_year
    end
  end
  

end
