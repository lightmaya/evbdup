# -*- encoding : utf-8 -*-
# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
# *.png *.jpg *.jpeg *.gif
config.assets.precompile += %w(style-switcher.css common.css *.png *.jpg *.jpeg *.gif ie_9.js form.js kobe.js kobe.css james.js james.css)
