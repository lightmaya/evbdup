# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

RAILS_ROOT = File.dirname(__FILE__) + '/..'
set :output, "#{RAILS_ROOT}/log/whenever.log"

# 每天 0点 统计评价分 超过45天 自动评价
every 1.days, :at => '00:00' do
  rake "everyday:update_order_rate"
end

# 每天 1点 生成进入用户平台 统计数据
every 1.days, :at => '01:00' do
  rake "everyday:create_cache_dep_main"
end
