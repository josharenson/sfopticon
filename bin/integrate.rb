#!/usr/bin/ruby

unless ENV.has_key? 'SFOPTICON_HOME' and Dir.exist? ENV['SFOPTICON_HOME']
	ENV['SFOPTICON_HOME'] = File.join(File.dirname(__FILE__), '..')
end

# Custom lib path and lib requires
$:.unshift ENV['SFOPTICON_HOME']
$:.unshift File.join(ENV['SFOPTICON_HOME'], 'lib')
require 'sfopticon'
require 'thor'

class IntegrationCLI < Thor
	desc "rebase", "Merge down any changes that have occurred in production since last rebase."
	option :org, :type => :string, :required => true
	def rebase
		prod = SfOpticon::Environment.find_by_production(true)
		this = SfOpticon::Environment.find_by_name(options[:org])

		if this
			this.integrate(prod)
		else
			abort "Environment #{options[:org]} not found."
		end
	end
end
IntegrationCLI.start(ARGV)