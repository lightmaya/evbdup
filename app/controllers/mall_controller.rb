# -*- encoding : utf-8 -*-
class MallController < ApplicationController
  before_action :check_token, :only =>[:create_order, :update_order]

  # 登录跳转到电商平台
  def go_to_mall
    if current_user && current_user.cgr?
      redirect_to :action => "redirect_to_dota"
    else
      redirect_to "#{get_dota_url}"
    end
  end

  # 判断是否登录
  def redirect_to_dota
    if current_user && current_user.cgr?
      url = "#{get_dota_url(params[:back])}/api/get_user_token"
      topname = current_user.user_type == 2 ? current_user.bumen.first_class.name : "中国储备粮管理总公司"
      user_params = {"token" => get_token(params[:back]), "userid" => current_user.id, "username" => current_user.login, "realname" => current_user.name, "usertype" => current_user.user_type, "topname" => current_user.real_department, "depname" => current_user.real_department.name, "depcode" => current_user.bumen.code}
      rs = get_api(url,user_params)
      if rs["success"] == true
        redirect_url = "#{get_dota_url(params[:back])}/api/token_sign_in?auth_token=#{rs['auth_token']}&token=#{get_token(params[:back])}"
        redirect_url << "&back=#{params[:back]}" unless params[:back].blank?
        redirect_to redirect_url
      else
        render :text => rs["desc"]
      end
    else
      if current_user.user_type == 3
        render :text => "非中储粮系统内单位不能登录办公用品网上商城！"
      else
        redirect_to sign_in_users_path  # 登录页面
      end
    end
  end

  # 获取token
  def get_token(url='')
    tk = MallToken.login_token.first
    if tk.nil? || tk.expires_at< Time.now
      sign = Digest::MD5::hexdigest(DOTA_PASSWORD + DOTA_USERNAME + DOTA_PASSWORD)[5..12].upcase
      url = "#{get_dota_url(url)}/api/get_access_token"
      params = {"app_key" => DOTA_USERNAME, "app_secret" => DOTA_PASSWORD, "sign" => sign }
      rs = get_api(url,params)
      if rs["success"] == true
        if tk.nil?
          MallToken.login_token.create("token" => rs["token"], "expires_at" => rs["expires_at"])
        else
          tk.update_attributes("token" => rs["token"], "expires_at" => rs["expires_at"])
        end
        return rs["token"]
      else
        return false
      end
    else
      return tk.token
    end
  end

	# 获取access_token
  # 传入app_key, app_secret, sign
  def get_access_token
    username = params["app_key"]
    password = params["app_secret"]
    return render :json => {"success" => false, "desc" => "用户名或密码不能为空"} if username.blank? || password.blank?
    return render :json => {"success" => false, "desc" => "用户不存在"} unless username == ZCL_USERNAME
    return render :json => {"success" => false, "desc" => "密码错误"} unless password == ZCL_PASSWORD
    # 约定组合字符串
    sign = Digest::MD5::hexdigest(password + username + password)[5..12].upcase
    return render :json => {"success" => false, "desc" => "sign值不正确"} if sign != params["sign"]
    # uk = MallToken.order_token.find(:first, :conditions => "due_at > '#{(Time.now + 1.minutes).to_time}'")
    # if uk
    # 	render :json => {"success" => true, "desc" => "获取token成功", "token" => uk.access_token, "expires_at" => uk.due_at.to_s}
    # else
    aot =	MallToken.order_token.new
    aot.access_token = SecureRandom.hex
    aot.due_at = Time.now + 26.hours
    if aot.save
     render :json => {"success" => true, "desc" => "生成token成功", "token" => aot.access_token, "expires_at" => aot.due_at.to_s}
   else
     render :json => {"success" => false, "desc" => "生成token失败"}
   end
    # end
  end

  def create_order
    mall = DdcgInfo.find_by_mall_id(params["id"])
    return render :json => {"success" => false, "desc" => "ID已存在"} if mall
    if params["budget"].to_f == 0
      ddcg_params = DdcgParams.find_by_category_name("个人购物")
    else
     ddcg_params = DdcgParams.find_by_category_name("电商采购")
   end
   return render :json=> {"success" => false, "desc" => "ddcg_params参数有误"}if ddcg_params.blank?
   order = DdcgInfo.new
		order.category_id = ddcg_params.category_id # ddcg_params 对应的category_id
		order.mall_id = params["id"]
		sn_number = "000000"
		sn_number << params["id"]
		order.sn = "#{ddcg_params.ysdcode}#{Time.now.strftime('%Y%m%d')}#{sn_number[-6,sn_number.length()]}"
		order.ht_code = order.sn
		order.total = params["total"]
		user = YtwgUser.find_by_id(params["user_id"])
		return render :json=> {"success" => false, "desc" => "user有误"}if user.blank?
		dep_p = user.bumen
		order.dep_p_code = dep_p.code
		order.top_name = user.user_type == 1 ? "中国储备粮管理总公司" : dep_p.first_class.name
		order.dep_p_name = dep_p.name
		dep_s = DepSupplier.find_by_id(params["dep_s_id"])
		return render :json=> {"success" => false, "desc" => "dep_s有误"}if dep_s.blank?
		order.dep_s_name = dep_s.try(:name)
		order.dep_s_id = dep_s.try(:id)
		order.dep_p_man = params["dep_p_man"]
		order.dep_s_man = dep_s.try(:contact_name)
		order.dep_p_tel = params["dep_p_tel"].blank? ? '-' : params["dep_p_tel"]
		order.dep_p_mobile = params["dep_p_mobile"].blank? ? '-' : params["dep_p_mobile"]
		order.dep_s_tel = dep_s.try(:contact_tel)
		order.dep_s_mobile = '-'
		order.dep_p_add = params["dep_p_add"]
		order.dep_s_add = dep_s.try(:detail_address)
		order.bugget = params["budget"]
		order.user_id = user.id
		order.user_dep = dep_p.id
		order.status = get_status(params["status"])
		order.project_name = "#{Time.now.to_date()} #{order.dep_p_name}办公物资采购项目"
		order.yw_type = ddcg_params.yw_type
		order.product_catalog = ddcg_params.product_catalog
		order.ysd_time = Time.now
		order.user_type = user.user_type
		order.dep_s_user_type = 3
		order.detail = %Q{<?xml version="1.0" encoding="UTF-8"?>\n<root>\n  <param name="发票抬头" value="#{params["fpdw"]}"/>\n</root>}
		order.logs = created_logs(order.logs,user,order.status,'生成订单','网上商城自动生成订单。')
		# order.logs = %Q{<?xml version='1.0' encoding='UTF-8'?>\n<root>\n  <param 操作人类别='#{order.user_type}' 操作时间='#{Time.new.strftime("%Y-%m-%d %H:%M:%S").to_s}' 备注='' 操作内容='生成订单' 操作人单位='#{order.dep_p_name}' 操作人ID='#{order.user_id}' 操作人姓名='#{user.user_name}' 当前状态='#{order.status}' IP地址='#{request.remote_ip}|#{IPParse.parse(request.remote_ip).gsub("Unknown", "未知")}'/>\n</root>}

		return render :json => {"success" => false, "desc" => "保存主表失败!"} unless order.save
		product_count = 0
		save_money = 0
		total = 0
		ca_name = []
		eval(params["products"]).each do |par|
			product = DdcgProduct.new
			product.ddcg_info_id = order.id
			product.category_id = ddcg_params.category_id
			ca = ZclCategory.find_by_id(par["gid"])
			return render :json => {"success" => false, "desc" => "产品品目不存在!"} if ca.blank?
			product.zcl_category_id = ca.id
			product.category_code = ca.code
			product.product_type = ca.name
			product.product_name = par["name"]
			product.purchase_price = par["price"].to_f
			product.purchase_num = par["num"].to_f
			product.market_price = par["market_price"].to_f
			product.unit = par["unit"]
			product.total = product.purchase_price.to_f * product.purchase_num.to_f
			product_count += product.purchase_num
			save_money += (product.market_price.to_f - product.purchase_price.to_f) * product.purchase_num.to_f
			total += product.total.to_f
			ca_name << product.product_type
			return render :json => {"success" => false, "desc" => "保存产品[#{par["name"]}]失败"} unless product.save
		end

		update_params = { :product_count => product_count, :save_money => save_money, :project_name => "#{Time.now.to_date()} #{order.dep_p_name}#{ca_name.uniq.join("、")}采购项目" }
		update_params[:total] = total unless order.total.to_f == total.to_f

		return render :json => {"success" => false, "desc" => "更新失败"} unless order.update_attributes(update_params)

    render :json => {"success" => true, "desc" => "生成订单成功"}
  end

  def update_order
    order = DdcgInfo.find_by_mall_id(params["id"])
    if order.blank?
     render :json => {"success" => false, "desc" => "ID不存在"}
   else
     user = YtwgUser.find_by_id(order.user_id)
     logs = created_logs(order.logs,user,get_status(params["status"]),'更新订单','网上商城同步更新订单。')
     if order.update_attributes(:status => get_status(params["status"]),:logs => logs)
      render :json => {"success" => true, "desc" => "更新订单成功"}
    else
      render :json => {"success" => false, "desc" => "更新订单失败"}
    end
  end
end

	# "cutting" => "已拆单", "wait_pay" => "正在处理", "paid" => "等待收货", "stockout" => "缺货中", "returning" => "退换货中", "canceled" => "已取消", "half_canceled" => "部分取消", "finished" => "已完成"
	def get_status(status)
		rs = ""
		case status
		when "finished", "half_canceled", "returning"
			rs = "已完成"
		when "wait_pay", "paid", "stockout"
			rs = "订单等待确认"
		when "canceled"
			rs = "已作废"
		when "cutting"
			rs = "已拆单"
		end
		return rs
	end

	# 生成日志
	def created_logs(logs,user,status,content,remark='')
    unless logs.nil?
      new_doc = Nokogiri::XML(logs)
    else
      new_doc = Nokogiri::XML::Document.new()
      new_doc.encoding = "UTF-8"
      new_doc << "<root>"
    end
    node = new_doc.root.add_child("<param>").first
    node["操作时间"] = Time.new.strftime("%Y-%m-%d %H:%M:%S").to_s
    node["操作人ID"] = user.try(:id).to_s
    node["操作人姓名"] = user.try(:user_name).to_s
    node["操作人类别"] = user.try(:user_type).to_s
    node["操作人单位"] = user.try(:bumen).blank? ? "" : user.bumen.name.to_s
    node["操作内容"] = content
    node["当前状态"] = status
    node["备注"] = remark
    node["IP地址"] = "#{request.remote_ip}|#{IPParse.parse(request.remote_ip).gsub("Unknown", "未知")}"
    return new_doc.to_s
  end


  private

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
    def get_dota_url(url='')
      # rs = "http://mall.sinograin.com.cn"
      rs = "http://127.0.0.13:3000"
      unless url.blank?
        ["http://mall.sinograin.com.cn", "http://zcl.sinopr.org", "http://61.135.234.27"].each do |a|
          next unless url.include? a
          rs = a
        end
      end
      return rs
    end

    def check_token
      uk = MallToken.order_token.find_by_access_token(params["token"])
      return render :json => {"success" => false, "desc" => "token不正确"} unless uk
      return render :json => {"success" => false, "desc" => "token已过期"} if Time.now > uk.due_at
    end

end
