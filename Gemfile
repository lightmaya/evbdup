source 'http://ruby.taobao.org'
# source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.0.0'

# Use sqlite3 as the database for Active Record
gem 'mysql2','0.3.14'

group :assets do
	# Use SCSS for stylesheets
	gem 'sass-rails', '~> 4.0.0'

	# Use CoffeeScript for .js.coffee assets and views
	gem 'coffee-rails', '~> 4.0.0'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

	# Use Uglifier as compressor for JavaScript assets
	gem 'uglifier', '>= 1.3.0'
end

# 树形结构,ruby处理数据库tree结构
# gem 'ancestry', '2.0.0', :git => "git://github.com/stefankroes/ancestry.git"
gem 'ancestry', '~> 2.1.0'

# 数据库字段备注
gem 'migration_comments', '0.3.1'

# Use jquery as the JavaScript library
gem 'jquery-rails', '3.0.4'

# 类xml解析
gem "nokogiri", "~> 1.6.1"

# 分页
gem 'kaminari', '~> 0.15.1'

# 静态配置信息
gem "settingslogic", "~> 2.0.9"

# 动态配置信息
gem "rails-settings-cached", "~> 0.3.2"

# 验证码
gem 'easy_captcha'

# 百度富文本编辑器
gem "ueditor-rails", "~> 1.2.5.3"

#上传组件
gem "paperclip", "~> 3.5.2"

# 文件上传（已通过JS实现)
# gem 'jquery-fileupload-rails', '~> 0.4.1'

#图片处理
# gem "rmagick", "~> 2.13.2"

gem 'mini_magick', '4.0.0'

#表单JS验证
# gem "jQuery-Validation-Engine-rails", "~> 0.0.2"

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

gem "simple_form", "~> 3.0.1"

gem "ipparse", "~> 0.2.0"

gem "rails-i18n", "~> 4.0.1"

# Use ActiveModel has_secure_password 密码验证 目前暂时不支持高版本3.1.5
gem "bcrypt-ruby", "~> 3.0.1" 
# gem 'bcrypt', '~> 3.1.7'
# gem "bcrypt-ruby", "~> 3.1.5"

# 权限校验
gem 'cancancan', '~> 1.7'


# Use unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano', group: :development

# Use debugger
# gem 'debugger', group: [:development, :test]

group :development, :test do
	# console print&debug 这个是手动，需要在代码里面写binding.pry
	gem "pry-rails", "~> 0.3.2"
	# 这2个加起来是自动，报错的地方会停下来，也能写代码
  gem 'better_errors', '~> 2.0.0'
  gem "binding_of_caller", "~> 0.7.2"
  # 开发模式加速
  gem 'rails-dev-tweaks', '~> 1.2.0'
  gem 'rake', '~> 10.4.2'
end
