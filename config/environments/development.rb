# -*- encoding : utf-8 -*-
Evbdup::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  # config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # 虚拟机测试环境在外部访问，友好错误提示
  BetterErrors::Middleware.allow_ip! "10.0.2.2"

  config.dev_tweaks.autoload_rules do
    keep :all

    skip '/favicon.ico'
    skip :assets
    keep :forced
  end

  # 设置 Action Mailer 发邮件
  config.action_mailer.default :charset => "utf-8", :content_type => "text/html"   #  设置发送邮件的内容的编码类型和发送邮件的默认内容类型
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address => "smtp.163.com",
    :port => 25,
    :domain => "163.com",
    :user_name => "zcladmin@163.com",
    :password => "zcl100044",
    #是否允许SMTP客户机使用用户ID AND PASSWORD或其他认证技术向服务器正确标识自己的身份,plain使用文本方式的用户名和认证id和口令 
    :authentication => :login, 
    #是否使用ttl/lls加密，当为'true'时，必须使用官网提供的ttl端口号，gmail为587
    :enable_starttls_auto => true 
  }
  config.action_mailer.raise_delivery_errors = true

  ActiveSupport::Dependencies.autoload_paths << File::join( Rails.root, 'lib')
ActiveSupport::Dependencies.explicitly_unloadable_constants << 'my_form.rb'
end
