##
# Class for managing branches.
#
# This class handles non-integration branches only,
# therefore all merging should be done in an integration_branch
# {SfOpticon::Environment}.
#
# @attr [String] name
#    The name of the branch. This may not reflect the
#    name of the Salesforce environment as this could
#    be an integration branch.
class SfOpticon::Branch < ActiveRecord::Base
  include SfOpticon::Scm.adapter

  attr_reader :log

  attr_accessible :name
  belongs_to :environment

  after_initialize do |branch|
    @log = SfOpticon::Logger
    init
  end

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

  def update
    update_branch(name)
  end
