namespace :db do
  task :migrate do
    Rake::Task["db:migrate_report"].invoke
  end

  task :migrate_report do
    ActiveRecord::Base.establish_connection(:report)
    ActiveRecord::MigrationContext.new("db/migrate_report/").migrate()
  end
end
