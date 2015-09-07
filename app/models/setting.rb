# -*- encoding : utf-8 -*-
class Setting < RailsSettings::CachedSettings
end

# The syntax is easy. First, lets create some settings to keep track of:

# Setting.admin_password = 'supersecret'
# Setting.date_format    = '%m %d, %Y'
# Setting.cocktails      = ['Martini', 'Screwdriver', 'White Russian']
# Setting.foo            = 123
# Setting.credentials    = { :username => 'tom', :password => 'secret' }
# Now lets read them back:

# Setting.foo            # returns 123
# Changing an existing setting is the same as creating a new setting:

# Setting.foo = 'super duper bar'
# For changing an existing setting which is a Hash, you can merge new values with existing ones:

# Setting.merge!(:credentials, :password => 'topsecret')
# Setting.credentials    # returns { :username => 'tom', :password => 'topsecret' }
# Decide you dont want to track a particular setting anymore?

# Setting.destroy :foo
# Setting.foo            # returns nil
# Want a list of all the settings?

# Setting.all
# # returns {'admin_password' => 'super_secret', 'date_format' => '%m %d, %Y'}
# You need name spaces and want a list of settings for a give name space? Just choose your prefered named space delimiter and use Setting.all like this:

# Setting['preferences.color'] = :blue
# Setting['preferences.size'] = :large
# Setting['license.key'] = 'ABC-DEF'
# Setting.all('preferences.')
# # returns { 'preferences.color' => :blue, 'preferences.size' => :large }
# Set defaults for certain settings of your app. This will cause the defined settings to return with the Specified value even if they are not in the database. Make a new file in config/initializers/default_settings.rb with the following:

# Setting.defaults[:some_setting] = 'footastic'
# Setting.where(:var => "some_setting").count
# => 0
# Setting.some_setting
# => "footastic"
# Init defualt value in database, this has indifferent with Setting.defaults[:some_setting], this will save the value into database:

# Setting.save_default(:some_key, "123")
# Setting.where(:var => "some_key").count
# => 1
# Setting.some_key
# => "123"
# Settings may be bound to any existing ActiveRecord object. Define this association like this: Notice! is not do caching in this version.

# class User < ActiveRecord::Base
#   include RailsSettings::Extend
# end
# Then you can set/get a setting for a given user instance just by doing this:

# user = User.find(123)
# user.settings.color = :red
# user.settings.color # returns :red
# user.settings.all # { "color" => :red }
# I you want to find users having or not having some settings, there are named scopes for this:

# User.with_settings
# # => returns a scope of users having any setting

# User.with_settings_for('color')
# # => returns a scope of users having a 'color' setting

# User.without_settings
# # returns a scope of users having no setting at all (means user.settings.all == {})

# User.without_settings('color')
# # returns a scope of users having no 'color' setting (means user.settings.color == nil)

# --------------------------------------------------------------------------------

# How to create a list, form to manage Settings?
# If you want create an admin interface to editing the Settings, you can try methods in follow:

# class SettingsController < ApplicationController
#   def index
#     # to get all items for render list
#     @settings = Setting.unscoped
#   end

#   def edit
#     @setting = Setting.unscoped.find(params[:id])
#   end
# end
# That's all there is to it! Enjoy!
