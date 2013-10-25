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

  attr_reader :log

  attr_accessible :name
  belongs_to :environment
  has_many :integration_branches

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

  ##
  # Integrates changes from any given environment into this
  # env. This will merge the changes in the underlying scm
  # as well as performing the deploy.
  #
  # @param src_env [SfOpticon::Environment] The environment to merge in
  def integrate(src_env)
    log.info { "Integrating changes in #{src_env} into #{name}."}

    # We lock so a scanner can't change our branch out from under us
    src_env.lock
    environment.lock

    # Make sure our local master branch has all the data
    update_branch(src_env.branch.name)

    # Make and switch to a throwaway branch
    int_branch_name = make_integration_branch(src_env.name)
    checkout(int_branch_name)

    # Merge in latest from the source environment
    merge(src_env.branch.name)

    changeset = calculate_changes_on_int(src_env)
    log.debug {
      changeset.keys.each do |action|
        changeset[action].each do |rec|
          "#{action} - #{rec}"
        end
      end
    }

    has_changes = !(changeset[:deleted].empty? && changeset[:added].empty?)

    if has_changes
      if changeset[:deleted].size > 0
        environment.deploy(changeset[:deleted], true)
      end

      if changeset[:added].size > 0
        environment.deploy(changeset[:added])
      end
    else
      log.info { "No changes from master. Rebase complete. "}
    end

    # It's possible for the 2 environments to be a little out of
    # sync. So even if there are no changes, that could just mean
    # it's a delete that didn't already exist in destination. In
    # that case we still want to do the merge so it doesn't continue
    # to try with each integration.

    # If that was successful we're going to merge the changes
    # back into our own branch, tag, and push to origin.
    checkout(name)
    merge(int_branch_name)
    add_tag(int_branch_name)

    # If that was successful we push to the repository
    push

    # And make sure to snapshot the environment
    environment.snapshot

    delete_integration_branch(int_branch_name)
    environment.unlock
    src_env.unlock
  end
end
