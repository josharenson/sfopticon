#!/usr/bin/ruby

# Custom lib path and lib requires
$:.unshift File.join(File.dirname(__FILE__), '..')
$:.unshift File.join(File.dirname(__FILE__), '../lib')
require 'opticon'
require 'opticon/db/schema'
require 'thor'

class ScannerCLI < Thor
	desc "snapshot", "Perform a clean snapshot of the Salesforce organization."
	option :org, :type => :string, :required => true
	option :type, :desc => "The Metadata type to retrieve, defaults to all"
	def snapshot
		Opticon::Scan.new(
			Opticon::Schema::Environment.find_by_name(options[:org]),
			options[:type]
		).snapshot
	end		

	desc "changeset", "Perform a changeset analysis of the Salesforce organization"
	option :org, :type => :string, :required => true
	option :type, :desc => "The Metadata type to retrieve, defaults to all"	
	def changeset
		Opticon::Scan.new(
			Opticon::Schema::Environment.find_by_name(options[:org]),
			options[:type]
		).changeset
	end

	desc "manifest", "Generate the complete manifest of the Salesforce organization"
	option :org, :type => :string, :required => true
	def manifest
		puts Opticon::Schema::Environment.find_by_name(options[:org]).snapshot_manifest
	end
end

ScannerCLI.start(ARGV)
