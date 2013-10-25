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
    integrate(options[:source], options[:destination])
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
