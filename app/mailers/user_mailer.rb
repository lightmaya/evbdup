# -*- encoding : utf-8 -*-
class UserMailer < ActionMailer::Base
  default from: "zcladmin@163.com"
  # self.async = true

  def registration_confirmation(user)
  	@user = user
  	email_with_name = @user.name.blank? ? @user.email : "#{@user.name} <#{@user.email}>"
		mail(to: email_with_name, subject: "激活邮件")
  end

end
