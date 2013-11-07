unless ENV.has_key? 'SFOPTICON_HOME' and Dir.exist? ENV['SFOPTICON_HOME']
	ENV['SFOPTICON_HOME'] = File.dirname(__FILE__)
end

$:.unshift ENV['SFOPTICON_HOME']
$:.unshift File.join(ENV['SFOPTICON_HOME'], 'lib')

require 'sfopticon'
require 'octokit'
require 'date'
require 'extlib'
require 'fileutils'
require 'active_record_migrations'
require 'yard'

ActiveRecordMigrations.configure do |c|
  c.yaml_config = 'application.yml'
  c.environment = 'database'
  c.db_dir = 'lib/sfopticon/db'
end
ActiveRecordMigrations.load_tasks

YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb']
  t.options = ['--quiet']
end

task :db_configuration do
  @db_config = SfOpticon::Settings.database
end

task :connect_to_db => :db_configuration do
  ActiveRecord::Base.establish_connection @db_config
end

task :create_db => :db_configuration do
  db_name = @db_config.database
  tmp_config = @db_config.dup
  tmp_config.delete 'database'

  ActiveRecord::Base.establish_connection tmp_config
  puts "Dropping database #{db_name}"
  ActiveRecord::Base.connection.drop_database db_name rescue nil

  puts "Creating database #{db_name}"
  ActiveRecord::Base.connection.create_database db_name
  puts "Database #{@db_config.database} created."
end

task :setup_db => [:create_db, 'db:schema:load']

task :doc => :yard do
  puts "Documentation generated and placed in ./doc. You can run a local server by executing 'yard server'"
end

task :delete_repo do
  repo_name = ENV['repo_name']

  unless repo_name
    repo_name = SfOpticon::Environment.find_by_production(true).name
  end

  config = SfOpticon::Settings.scm
  octo = Octokit::Client.new :login => config.username, :password => config.password
  repo = Octokit::Repository.from_url "#{config.url}/#{repo_name}"
  if octo.delete_repo(repo)
    puts "Repository #{repo} deleted."
  else
    puts "An unknown issue occurred. Repo #{repo} not deleted."
  end
end

task :reset => [:delete_repo, :setup_db]
