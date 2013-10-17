require 'metaforce'
require 'fileutils'

class SfOpticon::Environment < ActiveRecord::Base
  attr_reader :sforce
  validates_uniqueness_of :name, 
                          :message => "This organization is already configured."
  attr_accessible :name, 
                  :username, 
                  :password,
                  :production,
                  :locked
                
  has_many :sf_objects, :dependent => :destroy
  has_one  :branch

  # Setup variables
  after_initialize do |env|
    @log = SfOpticon::Logger
    @config = SfOpticon::Settings.salesforce
    @sforce = SfOpticon::Salesforce.new(self)
  end

  ##
  # This method is called when an environment is first created. This allows
  # us to reach out and create the remote repository if needed, or the branch.
  # This will also clone the branch and speak into the README.md
  after_create do |env|
    if production
      # If we're a production environment then we need to create the remote
      # repository
      SfOpticon::Scm.adapter.create_remote_repository(name)
    end

    create_branch(name: production ? 'master' : name)

    snapshot

    # We ignore the actual metadata in salesforce unless this is production.
    # We do this because we want them to start at the same logical place, as
    # though the non-production environment was refreshed even if it wasn't.
    if production
      sforce.retrieve :manifest => @sforce.manifest(sf_objects),
                      :extract_to => branch.local_path
      branch.add_changes
      branch.commit("Initial push of production code")
      branch.push
    end
  end

  ##
  # Locks the environment to prevent the changeset tool from making any
  # changes. This is necessary so that integration branches will have
  # a pristine head to work from
  def lock
    self.locked = true
    save!
  end

  ##
  # Unlocks the environment.
  def unlock
    self.locked = false
    save!
  end

  ##
  # Rebases our branch from production
  def rebase
    branch.rebase
  end

  ##
  # Takes a set of sf_objects and creates the directory/file layout
  # for a destructive change. We then call on to deploy_to_me.
  def deploy_destructive_changes(sf_objects)
    Dir.mktmpdir do |dir|
      @log.debug { "Created directory #{dir} destructive changes."}

      # Create an empty package.xml
      File.open(File.join(dir, 'package.xml'), 'w') do |f|
        f.puts(sforce.manifest([]).to_xml)
      end

      # Now we need a proper destructiveChanges.xml
      File.open(File.join(dir, 'destructiveChanges.xml'), 'w') do |f|
        f.puts(sforce.manifest(sf_objects).to_xml)
      end

      deploy_to_me(dir)
    end
  end

  ##
  # Takes a set of sf_objects and their source directory and creates
  # a deployment package.xml, and then deploys.
  def deploy_productive_changes(src_dir, sf_objects)
    File.open(File.join(src_dir, 'package.xml'), 'w') do |f|
      f.puts(sforce.manifest(sf_objects).to_xml)
    end

    deploy_to_me(src_dir)
  end

  ##
  # Deploys code changes to this environment. If this is a destructive change
  # then the destructiveChanges.xml must live in the root of the src_dir
  # parameter.
  #
  # @param src_dir [String] The source directory for the deployment. The 
  #    package.xml must exist in the root of the directory.
  def deploy_to_me(src_dir)
    @log.info { "Deploying changes from #{src_dir} to me"}
    sforce.client.deploy(src_dir)
      .on_complete {|job| @log.info { "Deploy complete: #{job.id}"}}
      .on_error    {|job| @log.error { "Deployment failed!"}}
      .perform
  end

  ##
  # Removes all sf_objects (via delete_all to avoid instantiation cost), the
  # local repo directory, and itself. This does *not* remove any remote repos!
  def remove
    # We skip the instantiation and go straight to single
    # statement deletion
    sf_objects.delete_all

    # Discard the org contents.
    begin
      FileUtils.remove_dir("#{SfOpticon::Settings.scm.local_path}/#{name}")
    rescue Errno::ENOENT
      # We pass if the directory is already gone
    end

    delete
  end

  # Create's a clean snapshot of all SF metadata related to the
  # configured types.
  def snapshot
    ## Env has to have it's current sf_objects wiped out
    @log.info { "Deleting all sfobjects for #{name}" }
    sf_objects.delete_all
    
    SfOpticon::SfObject.transaction do
      sforce.gather_metadata.each do |o|
        sf_objects << SfOpticon::SfObject.create(o)
      end
      save!
    end
  end

  # Generates a changeset from the latest snapshot and the current
  # metadata information from Salesforce. This changeset is then
  # committed to both the database and the repository.
  #
  # Returns the changeset
  def changeset
    curr_snap = sforce.gather_metadata
    diff = SfOpticon::ChangeMonitor::Diff.diff(sf_objects, curr_snap)
    if diff.size == 0
      @log.info { "No changes detected in #{name}" }
      return
    end

    # We now have an array of objects that have been deleted, renamed, added,
    # or modified in the correct order. We will replay these changes into the
    # local repository and the database.

    # First we have to generate a manifest of the additions and modifications
    # to retrieve those new objects
    mods = diff.select {|x|
      x[:type] == :add || x[:type] == :modify
    }.map {|x| x[:object] }

    # Retrieve the changes into a temporary directory
    dir = Dir.mktmpdir("changeset")
    sforce.retrieve(:manifest => sforce.manifest(mods), :extract_to => dir)

    # Now we replay the changes into the repo and the database
    diff.each do |change|
      @log.info { "DIFF: #{change[:type]} - #{change[:object][:full_name]}" }

      commit_message = "#{change[:type].to_s.capitalize} - #{change[:object][:full_name]}\n\n"
      if change[:type] == :delete
        commit_message += "#{change[:object][:file_name]} deleted"
      else      
        change[:object].keys.each do |key|
          commit_message += "#{key.to_s.camelize}: #{change[:object][key]}\n"
        end
      end

      # We have to copy the metadata files for Apex classes since they don't
      # embed their information on their own.
      meta_xml = if File.exist? "#{dir}/#{change[:object][:file_name]}-meta.xml"
        true
      else
        false
      end

      # Shortcuts until this trash is refactored out
      if change.has_key? :old_object
        old_file = change[:old_object][:file_name]
      end
      new_file = change[:object][:file_name]

      case change[:type]
      when :delete
        branch.delete_file(new_file)
        if meta_xml
          branch.delete_file("#{new_file}-meta.xml")
        end

        branch.add_changes
        branch.commit(commit_message, change[:object][:last_modified_by_name])
        sf_objects
          .find_by_sfobject_id(change[:object][:sfobject_id])
          .delete()

      when :rename
        branch.rename_file(old_file, new_file)
        if meta_xml
          branch.rename("#{old_file}-meta.xml", "#{new_file}-meta.xml")
        end

        branch.add_changes
        branch.commit(commit_message, change[:object][:last_modified_by_name])        
        sf_objects
          .find_by_sfobject_id(change[:old_object][:sfobject_id])
          .clobber(change[:object])

      when :add
        branch.add_file("#{dir}/#{new_file}", new_file)
        if meta_xml
          branch.add_file("#{dir}/#{new_file}-meta.xml", "#{new_file}-meta.xml")
        end

        branch.add_changes
        branch.commit(commit_message, change[:object][:last_modified_by_name])        
        sf_objects << sf_objects.new(change[:object])

      when :modify
        branch.clobber_file("#{dir}/#{new_file}", new_file)
        if meta_xml
          branch.clobber_file("#{dir}/#{new_file}-meta.xml", "#{new_file}-meta.xml")
        end

        branch.add_changes
        branch.commit(commit_message, change[:object][:last_modified_by_name])        
        sf_objects
          .find_by_sfobject_id(change[:object][:sfobject_id])
          .clobber(change[:object])

      end
    end
    save!
    branch.push
    FileUtils.remove_entry_secure(dir)

    @log.info { "Complete." }
    diff
  end
end