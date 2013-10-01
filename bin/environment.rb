#!/usr/bin/ruby

require 'thor'

# Custom lib path and lib requires
$:.unshift File.join(File.dirname(__FILE__), '..')
$:.unshift File.join(File.dirname(__FILE__), '../lib')
require 'sfopticon'

class EnvironmentCLI < Thor
	desc "list", "List existing Salesforce organizations"
	def list
		env_list = SfOpticon::Schema::Environment.all
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
		env = SfOpticon::Schema::Environment.find_by_name(options[:org])
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
		env = SfOpticon::Schema::Environment.find_by_name(options[:org])
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
		env = SfOpticon::Schema::Environment.find_by_name(options[:org])
		options.keys.select {|x| x != 'org' }.each do |key|
			env[key] = options[key]
			puts "#{key.to_s.capitalize} set to #{options[key]}"
		end
		env.save!
	end

	option :name, :type => :string, :required => true
	option :username, :type => :string, :required => true
	option :password, :type => :string, :required => true
	option :production, :type => :boolean, :default => false
	desc "create", "Create a new Salesforce organization"
	def create
		# Only 1 production environment
		if options[:production] and SfOpticon::Schema::Environment.find_by_production(true)
			puts "A production environment already exists"
			exit
		end

		# If no production environment exists then we must create that first
		unless options[:production] and not SfOpticon::Schema::Environment.find_by_production(true)
			puts "A production environment must be configured"
			exit
		end

		if SfOpticon::Schema::Environment.find_by_name(options[:name]) then
			puts "Salesforce organization #{options[:name]} already exists"
			exit
		end

		env = SfOpticon::Schema::Environment.create(options)
		env.init
		puts "Environment #{env.name} (#{env.username})- Created"
	end
end

EnvironmentCLI.start(ARGV)
