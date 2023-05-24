namespace :db do
  task :rollback do
    ActiveRecord::Base.establish_connection(:report)
    ActiveRecord::MigrationContext.new("db/migrate_report/").rollback()
  end
end
