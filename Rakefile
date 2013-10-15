unless ENV.has_key? 'SFOPTICON_HOME' and Dir.exist? ENV['SFOPTICON_HOME']
	ENV['SFOPTICON_HOME'] = File.dirname(__FILE__)
end

$:.unshift ENV['SFOPTICON_HOME']
$:.unshift File.join(ENV['SFOPTICON_HOME'], 'lib')

require 'sfopticon'
require 'date'
require 'extlib'
require 'fileutils'
require 'active_record_migrations'

ActiveRecordMigrations.configure do |c|
	c.yaml_config = 'application.yml'
	c.environment = 'database'
	c.db_dir = 'lib/sfopticon/db'
end
ActiveRecordMigrations.load_tasks

task :configuration do
	@db_config = SfOpticon::Settings.database
end

task :connect_to_db => :configuration do
	ActiveRecord::Base.establish_connection @db_config
end

task :create_db => :configuration do
	ActiveRecord::Base.establish_connection @db_config.merge('database' => nil)
	ActiveRecord::Base.connection.create_database @db_config.database
	ActiveRecord::Base.establish_connection @db_config
	puts "Database #{@db_config.database} created."
end

task :setup_db => [:create_db, 'db:schema:load']
