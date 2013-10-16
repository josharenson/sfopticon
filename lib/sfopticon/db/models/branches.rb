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

  after_initialize do |branch|
    @log = SfOpticon::Logger

    begin
      init
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
  end
end