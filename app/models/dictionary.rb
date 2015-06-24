# -*- encoding : utf-8 -*-
# gem 'settingslogic'
class Dictionary < Settingslogic
  source "#{Rails.root}/config/application.yml"
  namespace Rails.env
end
