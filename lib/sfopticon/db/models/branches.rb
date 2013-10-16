require 'pp'

##
# Class for managing branches. 
#
# All branch operations (merge etc.) should be performed
# through this branch class. This class belongs to 
# {SfOpticon::Environment}.
#
# @attr [String] name 
#    The name of the branch. This may not reflect the
#    name of the Salesforce environment as this could
#    be an integration branch.
class SfOpticon::Branch < ActiveRecord::Base
  include SfOpticon::Scm.adapter

  attr_accessible :name
  belongs_to :environment
  has_many :integration_branches

  after_initialize do |branch|
    @log = SfOpticon::Logger
    begin
      init
    rescue => e
      @log.debug { "Failed to init"}
    end
  end

  ##
  # If this is the creation of the branch then we want to clone
  # the remote repository, create the branch, and check it out.
  after_create do |branch|
    if Dir.exist? local_path
      FileUtils.remove_entry_secure(local_path)
    end

    make_branch
  end

  ##
  # Handles deletion including the directory removal
  def delete
    FileUtils.remove_entry_secure(local_path)
    super
  end

  ##
  # Rebases the current branch from production
  def rebase
    @log.info { "Rebasing #{name} from the production Salesforce instance"}
    environment.lock
    int_branch_name = "#{name}_rebase"

    # Make and switch to a throwaway branch
    make_integration_branch("#{name}_rebase")

    # Merge in latest master
    merge("origin/master")

    # Now we commit
    add_changes
    commit("Rebasing")

    changeset = calculate_changes(SfOpticon::Environment.find_by_production(true))

    if changeset[:deleted].size > 0
      environment.deploy_destructive_changes(changeset[:deleted])
    end

    if changeset[:added].size > 0
      environment.deploy_productive_changes(local_path, changeset[:added])
    end
  end
end

=begin
g.object('313163f22600b4128b88b3873b2c2880a136af8c').diff_parent.each do |df|
  [:patch, :path, :mode, :src, :dst, :type].each do |t|
    puts "#{t.to_s} -> #{df.send(t)}"
  end
end

g.log.between('master','ib_name').each do |c|
  ary = []
  g.object(c.sha).diff_parent.each {|df| ary.unshift(df) }
  ary.each do |df|
    [:patch, :path, :mode, :src, :dst, :type].each do |t|
      puts "#{t.to_s} -> #{df.send(t)}"
    end
    puts "--------------------"
  end
end

g.diff('master','ib_name').each do |c|
    [:patch, :path, :mode, :src, :dst, :type].each do |t|
      puts "#{t.to_s} -> #{c.send(t)}"
    end
    puts "--------------------"
end
=end