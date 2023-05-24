task :db_rollback_report do
  ActiveRecord::Base.establish_connection(:report)
  ActiveRecord::MigrationContext.new("db/migrate_report/").rollback()
end
