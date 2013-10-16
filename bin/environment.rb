#!/usr/bin/ruby

require 'thor'
require 'io/console'

unless ENV.has_key? 'SFOPTICON_HOME' and Dir.exist? ENV['SFOPTICON_HOME']
	ENV['SFOPTICON_HOME'] = File.join(File.dirname(__FILE__), '..')
end

# Custom lib path and lib requires
$:.unshift ENV['SFOPTICON_HOME']
$:.unshift File.join(ENV['SFOPTICON_HOME'], 'lib')
require 'sfopticon'

class EnvironmentCLI < Thor
	desc "list", "List existing Salesforce organizations"
	def list
		env_list = SfOpticon::Environment.all
		if env_list.empty?
			puts "No configured environments"
		else
			env_list.each do |env|
				puts "Name: #{env.name}"
			end
		end
	end

	option :org, :type => :string, :required => true
	desc "describe", "Displays the Salesforce organization's configuration"
	def describe
		env = SfOpticon::Environment.find_by_name(options[:org])
                if env.nil?
                  abort "Environment \"" + options[:org] + "\" not found."
                end
		puts " Environment ID #{env.id}"
		puts "-----------------------------------------------"
		puts "       Name: #{env.name}"
		puts "   Username: #{env.username}"
		puts "   Password: #{env.password}"
		puts " Production: #{env.production}"
	end

	option :org, :type => :string, :required => true
	desc "delete", "Deletes the Salesforce organization from the database"
	def delete
		env = SfOpticon::Environment.find_by_name(options[:org])
		unless env
			puts "Environment \"#{options[:org]}\" not found."
			exit
		end

		puts "Warning! This operation is irreversible!"
		printf "Are you sure you want to delete #{env.name}? [yn]: "
		answer = STDIN.getc

		if answer.downcase == "y"
			puts "Deleting all records from #{options[:org]}"
			env.remove
		elsif answer.downcase == "n"
			puts "Skipping."
		else
			puts "Invalid answer!"
			exit
		end
	end

	option :org, :type => :string, :required => true
	option :name, :type => :string
	option :username, :type => :string
	option :password, :type => :string
	option :production, :type => :boolean, :default => false
	desc "update", "Update the configuration of an existing Salesforce organization"
	def update
		env = SfOpticon::Environment.find_by_name(options[:org])
                if env.nil?
                  abort "Environment \"" + options[:org] + "\" not found."
                end
		options.keys.select {|x| x != 'org' }.each do |key|
			env[key] = options[key]
			puts "#{key.to_s.capitalize} set to #{options[key]}"
		end
		env.save!
	end

	option :name, :type => :string, :required => true
	option :username, :type => :string, :required => false
	option :password, :type => :string, :required => false
	option :production, :type => :boolean, :default => false
	desc "create", "Create a new Salesforce organization"
	def create
		opts_copy = options.dup

		# Only 1 production environment
		if opts_copy[:production] and SfOpticon::Environment.find_by_production(true)
			puts "A production environment already exists"
			exit
		end

		# If no production environment exists then we must create that first
		if not opts_copy[:production] and not SfOpticon::Environment.find_by_production(true)
			puts "A production environment must be configured"
			exit
		end

		if SfOpticon::Environment.find_by_name(opts_copy[:name])
			puts "Salesforce organization #{opts_copy[:name]} already exists"
			exit
		end

		# Retrieve the username from the command line if not supplied
		if not opts_copy[:username]
			print "Salesforce Login: "
			opts_copy[:username] = $stdin.gets.chomp
		end

		# Get the password (hidden) if it was not supplied on the cli
		if not opts_copy[:password]
			print "Salesforce Password: "
			opts_copy[:password] = STDIN.noecho(&:gets).chomp
		end

		begin
			env = SfOpticon::Environment.create(opts_copy)
		rescue Exception => e
			puts "Error creating remote repository. " + e.message
			puts "Attempting to rollback local changes..."

			begin
				SfOpticon::Environment.destroy(env)
			rescue ActiveRecord::RecordNotFound
			end
			abort "Successfully rolled back changes."
		end

		puts "Environment #{env.name} (#{env.username})- Created"
	end
end

EnvironmentCLI.start(ARGV)
