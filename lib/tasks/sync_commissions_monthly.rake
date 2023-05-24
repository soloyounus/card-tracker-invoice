require 'zip'
require "#{Rails.root}/config/environment"

# sync the report for the last seven years
# once per month, on final weekend only
namespace :sync do
  namespace :commissions do
    task :monthly, [:force] do | t, args |
      force = args[:force] || false

      if force || Date.today == last_sunday_of_month
        num_months = 7 * 12

        (num_months).times.reverse_each do |offset|
          Rake::Task["sync:commissions"].execute({
            num_months: 1,
            offset: offset,
          })
        end
      end
    end
  end
end

def last_sunday_of_month
  date = Date.today.end_of_month

  date - date.wday
end