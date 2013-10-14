$:.unshift ENV['SFOPTICON_HOME']
$:.unshift File.join(ENV['SFOPTICON_HOME'], 'lib')

require 'deep_symbolize'
require 'sfopticon/settings'
require 'logger'
require 'active_record'

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
	$stderr.puts "Database #{@db_config.database} created."
end

task :migrate => :connect_to_db do
	ActiveRecord::Migrator.migrate('lib/sfopticon/db/migrations/')
end