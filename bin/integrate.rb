#!/usr/bin/env ruby

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
    integrate(SfOpticon::Environment.find_by_production(true).name,options[:org])
  end

  desc "merge", "Merge and deploy changes from one environment to another."
  option :source, :type => :string, :required => true
  option :destination, :type => :string, :required => true
  def merge
    dest = SfOpticon::Environment.find_by_name(options[:destination])
    if dest.integration_branch.nil?
      integrate(options[:source], options[:destination])
    else
      puts "#{options[:destination]} already has an integration branch waiting \
to be deployed. Please deploy the changes, or merge into a different environment."
    end
  end

  desc "deploy","Deploy a staged integration branch to its destination environment."
  option :org, :type => :string, :required => true
  option :force, :type => :boolean, :required => false
  def deploy
    env = SfOpticon::Environment.find_by_name(options[:org])
    if env.nil? or env.integration_branch.nil?
      abort "#{options[:org]} does not exist or does not yet have an integration \
branch associated with it. Try doing a merge first."
    end
    src_env = SfOpticon::Environment.find_by_id(env.integration_branch.source_env)

    unless options[:force]
      puts "WARNING: This will deploy changes from #{src_env.name} that were \
merged into #{env.name} to the Salesforce environment pointed to by #{env.name}"
      print "Are you sure you want to deploy? [yn]: "
      answer = STDIN.getc

      if answer.downcase == "n"
        puts "Deploy aborted."
        exit
      elsif answer.downcase != "y"
        puts "Invalid answer!"
        exit
      end
    end
    env.integration_branch.deploy
  end
  
  desc "status","Check the integration branch status of this environment"
  option :org, :type => :string, :required => :true
  def status
    env = SfOpticon::Environment.find_by_name(options[:org])
    if env.integration_branch.nil?
      puts "#{options[:org]} does not have an integration branch associated with \
it. Please perform a merge first."
    else
      src_env = SfOpticon::Environment.find_by_id(env.integration_branch.source_env)
      say "#{env.name} has staged changes merged in from #{src_env.name} at \
#{env.integration_branch.created_at} that are awating deployment."
    end
  end

  no_commands {
    def integrate(src_name,dst_name)
      src = SfOpticon::Environment.find_by_name(src_name)
      dst = SfOpticon::Environment.find_by_name(dst_name)

      if src and dst
        dst.integrate(src)
      else
        abort "One or both environments were not found."
      end
    end
  }

end
IntegrationCLI.start(ARGV)
