# -*- encoding : utf-8 -*-
class MallController < ApplicationController
  before_action :check_token, :only =>[:create_order, :update_order]

  # 登录跳转到电商平台
  def index
    if current_user && current_user.cgr?
      redirect_to redirect_to_dota_mall_index_path(mall_type: params[:mall_type])
    else
      redirect_to get_dota_url(params[:mall_type], true)
    end
  end

  # 判断是否登录
  def redirect_to_dota
    if current_user && current_user.cgr?
      url = "#{get_dota_url(params[:mall_type])}/get_user_token"
      user_params = { "token" => get_token(params[:mall_type]), "userid" => current_user.id, "username" => current_user.login,
        "realname" => current_user.name, "usertype" => current_user.user_type,
        "topname" => current_user.department.top_dep.try(:name), "depname" => current_user.real_department.name,
        "depcode" => current_user.real_dep_code
      }
      rs = get_api(url,user_params)
      if rs["success"] == true
        redirect_url = "#{get_dota_url(params[:mall_type])}/token_sign_in?auth_token=#{rs['auth_token']}&token=#{get_token(params[:mall_type])}"
        # redirect_url << "&back=#{params[:back]}" unless params[:back].blank?
        redirect_to redirect_url
      else
        render :text => rs["desc"]
      end
    else
      if current_user.department.is_dep_supplier?
        render :text => "非中储粮系统内单位不能登录办公用品网上商城！"
      else
        redirect_to sign_in_users_path
      end
    end
  end

  # 获取token
  def get_token(url='')
    mt = url == "mall" ? MallToken.mall : MallToken.govbuy
    tk = mt.first
    if tk.nil? || tk.due_at.utc < Time.now
      sign = Digest::MD5::hexdigest(Dictionary.DOTA_PASSWORD + Dictionary.DOTA_USERNAME + Dictionary.DOTA_PASSWORD)[5..12].upcase
      url = "#{get_dota_url(url)}/get_access_token"
      params = {"app_key" => Dictionary.DOTA_USERNAME, "app_secret" => Dictionary.DOTA_PASSWORD, "sign" => sign }
      rs = get_api(url, params)
      if rs["success"] == true
        if tk.nil?
          mt.create(access_token: rs["token"], due_at: rs["expires_at"])
        else
          tk.update(access_token: rs["token"], due_at: rs["expires_at"])
        end
        return rs["token"]
      else
        return false
      end
    else
      return tk.access_token
    end
  end

  # 获取order access_token
  # 传入app_key, app_secret, sign
  def get_access_token
    username = params["app_key"]
    password = params["app_secret"]
    return render :json => {"success" => false, "desc" => "用户名或密码不能为空"} if username.blank? || password.blank?
    return render :json => {"success" => false, "desc" => "用户不存在"} unless username == Dictionary.ZCL_USERNAME
    return render :json => {"success" => false, "desc" => "密码错误"} unless password == Dictionary.ZCL_PASSWORD
    # 约定组合字符串
    sign = Digest::MD5::hexdigest(password + username + password)[5..12].upcase
    return render :json => {"success" => false, "desc" => "sign值不正确"} if sign != params["sign"]
    aot =	MallToken.find_or_initialize_by(name: 'order')
    aot.access_token = SecureRandom.hex
    aot.due_at = (Time.now + 26.hours).utc
    if aot.save
      render :json => {"success" => true, "desc" => "生成token成功", "token" => aot.access_token, "expires_at" => aot.due_at.utc.to_s}
    else
      render :json => {"success" => false, "desc" => "生成token失败"}
    end
  end

  def create_order
    mall = Order.find_by(mall_id: params["id"], yw_type: 'dscg')
    return render :json => {"success" => false, "desc" => "ID已存在"} if mall.present?
    user = User.find_by(id: params["user_id"])
    return render :json=> {"success" => false, "desc" => "user有误"} if user.blank?
    dep_s = Department.find_by(old_id: params["dep_s_id"], old_table: 'dep_supplier')
    return render :json=> {"success" => false, "desc" => "dep_s有误"}if dep_s.blank?

    order = Order.new
    order.mall_id = params["id"]
    order.yw_type = params["budget"].to_f == 0 ? 'grcg' : 'dscg'
    order.total = params["total"]
    order.budget_money = params["budget"]
    order.sn = "DSCG-#{Time.now.to_s(:number)[0...10]}#{('%04d' % params["id"])[-4...params["id"].size]}"
    order.contract_sn = order.sn.gsub("DSCG", "ZCL")

    order.buyer_name = user.real_department.name
    order.payer = params["fpdw"]
    order.buyer_id = user.department.id
    order.buyer_code = user.real_dep_code
    order.buyer_man = params["dep_p_man"]
    order.buyer_tel = params["dep_p_tel"].blank? ? '-' : params["dep_p_tel"]
    order.buyer_mobile = params["dep_p_mobile"].blank? ? '-' : params["dep_p_mobile"]
    order.buyer_addr = params["dep_p_add"]
    order.user_id = user.id

    order.seller_name = dep_s.try(:name)
    order.seller_id = dep_s.try(:id)
    order.seller_code = dep_s.try(:real_ancestry)
    order.seller_addr = dep_s.try(:address)

    order.seller_man = "-"
    order.seller_tel = "-"
    order.seller_mobile = "-"
    order.deliver_at = Date.today + 3

    order.status = get_status(params["status"])
    order.name = Order.get_project_name(order, user, '办公用品', order.yw_type)
    order.logs = created_logs(order, user, '生成订单', '网上商城自动生成订单。')

    return render :json => {"success" => false, "desc" => "保存主表失败!"} unless order.save
    eval(params["products"]).each do |par|
      ca = Category.find_by_id(par["gid"])
      return render :json => {"success" => false, "desc" => "产品品目[#{par["gid"]}]不存在!"} if ca.blank?
      p_name_arr = par["name"].split
      order.items.create(market_price: par["market_price"].to_f, quantity: par["num"].to_f, price: par["price"].to_f,
        category_id: ca.try(:id), category_code: ca.try(:ancestry), category_name: ca.try(:name),
        brand: p_name_arr[0], model: p_name_arr[1], version: (p_name_arr[2..p_name_arr.size].present? ? p_name_arr[2..p_name_arr.size].join : ''), unit: par["unit"],
        total: par["num"].to_f * par["price"].to_f
        )
    end

    update_params = { name: Order.get_project_name(order, user, order.items.map(&:category_name).uniq.join("、"), order.yw_type) }
    update_params[:total] = order.items.sum(:total).to_f unless order.total.to_f == order.items.sum(:total).to_f

    return render :json => {"success" => false, "desc" => "更新失败"} unless order.update(update_params)

    render :json => {"success" => true, "desc" => "生成订单成功"}
  end

  def update_order
    order = Order.find_by(mall_id: params["id"], yw_type: 'dscg')
    if order.blank?
      render :json => {"success" => false, "desc" => "ID不存在"}
    else
      user = User.find_by(id: order.user_id)
      logs = created_logs(order, user, '更新订单', '网上商城同步更新订单。')
      if order.update(status: get_status(params["status"]), logs: logs)
        render :json => {"success" => true, "desc" => "更新订单成功"}
      else
        render :json => {"success" => false, "desc" => "更新订单失败"}
      end
    end
  end

  private
  # "cutting" => "已拆单", "wait_pay" => "正在处理", "paid" => "等待收货", "stockout" => "缺货中", "returning" => "退换货中", "canceled" => "已取消", "half_canceled" => "部分取消", "finished" => "已完成"
  def get_status(status)
    rs = ""
    case status
    when "finished", "half_canceled", "returning"
      rs = "100"
    when "wait_pay", "paid", "stockout"
      rs = "11"
    when "wait_remit"
      rs = "86"
    when "deal_remit"
      rs = "79"
    when "canceled"
      rs = "47"
    when "cutting"
      rs = "5"
    end
    return rs
  end

  # 生成日志
  def created_logs(obj, user, action, remark='')
    prepare_logs_content(obj, action, remark, user)
  end

  # POST方法传参
  def get_api(url,params={})
    unless url.blank?
      x = Net::HTTP.post_form(URI.parse(url), params)
      h = ActiveSupport::JSON.decode(x.body)
      return h
    else
      return {"success" => false, "messages" => "URL为空"}
    end
  end

  # 电商平台的URL
  def get_dota_url(type='', home_index=false)
    case type
    when "mall"
      tmp = "http://mall.sinograin.com.cn"
      home_index ? tmp : "#{tmp}/api"
    when "govbuy"
      tmp = "http://sinograin.govbuy.cn"
      home_index ? tmp : "#{tmp}/backend/api/1"
    else
      ""
    end
  end

  def check_token
    uk = MallToken.order_token.find_by(access_token: params["token"], name: 'order')
    return render :json => {"success" => false, "desc" => "token不正确"} unless uk
    return render :json => {"success" => false, "desc" => "token已过期"} if Time.now > uk.due_at.utc
  end

end
