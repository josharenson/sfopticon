unless ENV.has_key? 'SFOPTICON_HOME' and Dir.exist? ENV['SFOPTICON_HOME']
	ENV['SFOPTICON_HOME'] = File.dirname(__FILE__)
end

$:.unshift ENV['SFOPTICON_HOME']
$:.unshift File.join(ENV['SFOPTICON_HOME'], 'lib')

require 'deep_symbolize'
require 'sfopticon/settings'
require 'logger'
require 'active_record'
require 'date'
require 'extlib'
require 'fileutils'

task :configuration do
	@db_config = SfOpticon::Settings.database
	@migrations_dir = "#{ENV['SFOPTICON_HOME']}/lib/sfopticon/db/migrations/"
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

task :migrate => :connect_to_db do
	ActiveRecord::Migrator.migrate(@migrations_dir)
end

task :generate_migration, [:name] => :configuration do |t,args|
	migration_name = args[:name]
	type = migration_name.split(/_/)[0]

	unless migration_name
		abort "A migration name must be provided"
	end

	filename = DateTime.now.strftime("%Y%m%d%H%M%S") + "_" + migration_name.snake_case + ".rb"

	unless Dir.exist? @migrations_dir
		FileUtils.mkdir_p @migrations_dir
	end

	File.open(File.join(@migrations_dir, filename), 'w') do |f|
		f.puts("class #{migration_name} < ActiveRecord::Migration")
		f.puts("  def change")
		f.puts("  end")
		f.puts("end")
	end

	puts "Migration #{filename} created in #{@migrations_dir}"
end