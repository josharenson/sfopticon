#!/usr/bin/ruby

unless ENV.has_key? 'SFOPTICON_HOME' and Dir.exist? ENV['SFOPTICON_HOME']
	ENV['SFOPTICON_HOME'] = File.join(File.dirname(__FILE__), '..')
end

# Custom lib path and lib requires
$:.unshift ENV['SFOPTICON_HOME']
$:.unshift File.join(ENV['SFOPTICON_HOME'], 'lib')
require 'sfopticon'
require 'thor'

class ScannerCLI < Thor
	desc "snapshot", "Perform a clean snapshot of the Salesforce organization.
	    WARNING: This may leave your local repository out of sync with your
	    Salesforce snapshot."
	option :org, :type => :string, :required => true
	option :type, :desc => "The Metadata type to retrieve, defaults to all"
	def snapshot
		SfOpticon::Environment.find_by_name(options[:org]).snapshot
	end		

	desc "changeset", "Perform a changeset analysis of the Salesforce organization"
	option :org, :type => :string, :required => true
	option :type, :desc => "The Metadata type to retrieve, defaults to all"	
	def changeset
		env = SfOpticon::Environment.find_by_name(options[:org])
		if env.locked?
			abort "This environment is currently locked."
		end

		env.changeset
	end
end

ScannerCLI.start(ARGV)
