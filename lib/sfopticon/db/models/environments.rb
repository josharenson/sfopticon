require 'metaforce'
require 'fileutils'

class SfOpticon::Environment < ActiveRecord::Base
  validates_uniqueness_of :name, :message => "This organization is already configured."
  attr_accessible :name, 
                  :username, 
                  :password,
                  :production
                
  has_many :sf_objects, :dependent => :destroy
  has_one  :branches
  after_initialize :after_initialize

  def after_initialize
    @log = SfOpticon::Logger
    @config = SfOpticon::Settings.salesforce
    @sforce = SfOpticon::Salesforce.new(self)
  end

  # Provide access to the SCM instance. 
  def scm
    @scm ||= SfOpticon::Scm.new(name)
  end

  def init_production
    @scm = SfOpticon::Scm.adapter.create_remote_repo(name)
  end

  def init_branch
    prod = SfOpticon::Scm.new(self.class.find_by_production(true).name)
    @scm = SfOpticon::Scm.adapter.create_branch(prod, name)
  end

  ##
  # Rebases this environment with any changes in production since
  # last integration.
  def rebase
    int = branch.make_branch
    int.merge_in(self.class.find_by_production(true).branch)
    int.deploy_to(self)
  end

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

  #### Init the repository
  # If this is the initial setup of the production system we'll want an empty
  # repository. The repository will need to be configured on the remote server
  # and empty.
  # 
  # If this isn't a production org, then we're going to want to branch from the
  # production org instead.
  def init
    @log.info { "Beginning snapshot of #{name}" }
    snapshot
    @log.info { "Snapshot complete" }

    if production
      init_production
      @sforce.retrieve :manifest => @sforce.manifest(sf_objects),
                       :extract_to => scm.local_path
      scm.add_changes
      scm.commit("Initial push of production code")
      scm.push()
    else
      init_branch
    end
  end

  # Create's a clean snapshot of all SF metadata related to the
  # configured types.
  def snapshot
    ## Env has to have it's current sf_objects wiped out
    @log.info { "Deleting all sfobjects for #{name}" }
    sf_objects.delete_all
    
    SfOpticon::SfObject.transaction do
      @sforce.gather_metadata.each do |o|
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
    curr_snap = @sforce.gather_metadata
    diff = SfOpticon::Diff.diff(sf_objects, curr_snap)
    if diff.size == 0
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
    @sforce.retrieve(:manifest => @sforce.manifest(mods), :extract_to => dir)

    # Now we replay the changes into the repo and the database
    diff.each do |change|
      @log.info { "DIFF: #{change[:type]} - #{change[:object][:full_name]}" }
      
      commit_message = "#{change[:type].to_s.capitalize} - #{change[:object][:full_name]}"

      if change[:type] == :delete
        commit_message = "#{change[:object][:file_name]} deleted"
      else
        change[:object].keys.each do |key|
          commit_message += "#{key.to_s.camelize}: #{change[:object][key]}\n"
        end
      end

      case change[:type]
      when :delete
        scm.delete_file(change[:object][:file_name])
        scm.add_changes
        scm.commit(commit_message, change[:object][:last_modified_by_name])
        sf_objects
          .find_by_sfobject_id(change[:object][:sfobject_id])
          .delete()

      when :rename
        scm.rename_file(change[:old_object][:file_name], change[:object][:file_name])
        scm.add_changes
        scm.commit(commit_message, change[:object][:last_modified_by_name])        
        sf_objects
          .find_by_sfobject_id(change[:old_object][:sfobject_id])
          .clobber(change[:object])

      when :add
        scm.add_file("#{dir}/#{change[:object][:file_name]}",change[:object][:file_name])
        scm.add_changes
        scm.commit(commit_message, change[:object][:last_modified_by_name])        
        sf_objects << sf_objects.new(change[:object])

      when :modify
        scm.clobber_file("#{dir}/#{change[:object][:file_name]}",change[:object][:file_name])
        scm.add_changes
        scm.commit(commit_message, change[:object][:last_modified_by_name])        
        sf_objects
          .find_by_sfobject_id(change[:object][:sfobject_id])
          .clobber(change[:object])

      end
    end
    save!
    scm.push(name,name)
    FileUtils.remove_entry_secure(dir)

    @log.info { "Complete." }
    diff
  end
end

