include ActiveRecord::Tasks

namespace :db do
  namespace :migrate do
    task :status do
      ActiveRecord::Base.establish_connection(:report)

      puts "\ndatabase: report\n\n"
      puts "#{'Status'.center(8)}  #{'Migration ID'.ljust(14)}  Migration Name"
      puts "-" * 50
      ActiveRecord::MigrationContext.new("db/migrate_report/").migrations_status.each do |status, version, name|
        puts "#{status.center(8)}  #{version.ljust(14)}  #{name}"
      end
      puts

    end
  end
end
