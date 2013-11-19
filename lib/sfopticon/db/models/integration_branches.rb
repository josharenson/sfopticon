class SfOpticon::IntegrationBranch < ActiveRecord::Base
  include SfOpticon::Scm.adapter

  attr_reader :log

  attr_accessible :name,
    :dest_env,
    :source_env,
    :pre_merge_commit_id,
    :post_merge_commit_id,
    :is_deployed

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
    @local_path = environment.branch.local_path
    make_integration_branch(branch.environment)
  end

  ##
  # Handles deletion including the directory removal
  def delete
    FileUtils.remove_entry_secure(local_path)
    super
  end

  def integrate(src_env)
    # We have to update the source branch so it gets the ref of the newly 
    # created integration branch
    update_branch(src_env.branch.name)

    self.pre_merge_commit_id  = checkout(name)
    self.post_merge_commit_id = merge(src_env.branch.name)
    save!

    checkout(src_env.branch.name)
  end

  def deploy
    environment.lock
    changeset = calculate_changes_on_int
    
    log.debug {
      changeset.keys.each do |action|
        changeset[action].each do |rec|
          "#{action} - #{rec}"
        end
      end
    }

    # Deploy the changes to Salesforce _first_ so we can abort the merge
    # if the unit tests fail :-)
    has_changes = if changeset[:deleted].empty? and changeset[:added].empty?
      false
    else
      true
    end
    
    log.debug { "has_changes == #{has_changes}" }
    if has_changes
      if changeset[:deleted].size > 0
        environment.deploy(changeset[:deleted], true)
      end
      if changeset[:added].size > 0
        environment.deploy(changeset[:added])
      end
    else
      log.info { "No changes to deploy."}
    end


    # Merge the integration branch back into head
    checkout(environment.branch.name)
    merge(name)
    #add_tag(name)
    push
    checkout(environment.branch.name)
    
    is_deployed = true
    environment.integration_branch = nil
    environment.snapshot
    environment.unlock
  end

end
