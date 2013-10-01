#!/usr/bin/ruby

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
		SfOpticon::Scan.new(
			SfOpticon::Schema::Environment.find_by_name(options[:org]),
			options[:type]
		).snapshot
	end		

	desc "changeset", "Perform a changeset analysis of the Salesforce organization"
	option :org, :type => :string, :required => true
	option :type, :desc => "The Metadata type to retrieve, defaults to all"	
	def changeset
		SfOpticon::Scan.new(
			SfOpticon::Schema::Environment.find_by_name(options[:org]),
			options[:type]
		).changeset
	end

	desc "manifest", "Generate the complete manifest of the Salesforce organization"
	option :org, :type => :string, :required => true
	def manifest
		puts SfOpticon::Schema::Environment.find_by_name(options[:org]).snapshot_manifest
	end
end

ScannerCLI.start(ARGV)
