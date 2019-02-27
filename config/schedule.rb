# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

every 15.minutes do
  runner "FileCheckJob.perform_now"
end

every 1.day, at: '5:30 am' do
  runner "DataExportJob.perform_now"
end

# want to run this on both app servers while we are using the filesystem
# as a cache to prevent filling up all the diskspace
every :day, at: '7:00pm', roles: [:app] do
  rake "tmp:cache:clear"
end

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
