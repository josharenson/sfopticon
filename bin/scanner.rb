#!/usr/bin/ruby

$root = File.join(File.dirname(__FILE__), '..')

# Custom lib path and lib requires
$:.unshift File.join(File.dirname(__FILE__), '..')
$:.unshift File.join(File.dirname(__FILE__), '../lib')
require 'sfopticon'
require 'sfopticon/db/schema'
require 'thor'

class ScannerCLI < Thor
	desc "snapshot", "Perform a clean snapshot of the Salesforce organization."
	option :org, :type => :string, :required => true
	option :type, :desc => "The Metadata type to retrieve, defaults to all"
	def snapshot
		SfOpticon::Schema::Environment.find_by_name(options[:org]).snapshot
	end		

	desc "changeset", "Perform a changeset analysis of the Salesforce organization"
	option :org, :type => :string, :required => true
	option :type, :desc => "The Metadata type to retrieve, defaults to all"	
	def changeset
		SfOpticon::Schema::Environment.find_by_name(options[:org]).changeset
	end
end

ScannerCLI.start(ARGV)