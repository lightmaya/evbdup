# -*- encoding : utf-8 -*-
class ErrorsController < ApplicationController

  # layout false

  def index
  	@no = params["no"] || "404"
  	@messages = transfer_code(@no)
  	# render :file => 'public/404.html' and return
  	# render :file => "#{Rails.root}/public/#{error_code}.html"
  end

  private

  def transfer_code(no)
  	ers = {
  		"404" => "页面不存在或者已过期",
  		"707" => "您的浏览器版本太低，建议升级到最新版本或者安装目前主流的<a href='http://www.firefox.com.cn' _target='blank'>火狐浏览器</a>。",
             "334" => %{
                您输入的信息与实际不符，详情请联系服务热线：<br>
                办公物资：#{Dictionary.service_bg_tel}。<br>
                粮机物资：#{Dictionary.service_lj_tel}。<br>
                技术支持：#{Dictionary.technical_support}。<br><br>
              }
  	}
  	return ers[no]
  end
end
