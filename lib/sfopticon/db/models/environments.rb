require 'metaforce'
require 'fileutils'

class SfOpticon::Schema::Environment < ActiveRecord::Base
  validates_uniqueness_of :name, :message => "This organization is already configured."
  attr_accessible :name, 
                  :username, 
                  :password,
                  :production
                
  has_many :sf_objects, :dependent => :destroy

  def initialize(*args)
    @log = SfOpticon::Logger
    @config = SfOpticon::Settings.salesforce
    @sforce = SfOpticon::Salesforce.new(self)
    super(*args)
  end

  # Provide access to the SCM instance. 
  def scm
    @scm ||= SfOpticon::Scm.new(:repo => name)
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
    snapshot

    if production
      init_production
      @sforce.retrieve :manifest => @sforce.manifest(sf_objects),
                       :extract_to => scm.path
      scm.add_changes
      scm.commit("Initial push of production code")
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
    
    SfOpticon::Schema::SfObject.transaction do
      @sforce.gather_metadata.each do |o|
        sf_objects << SfOpticon::Schema::SfObject.create(o)
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
    curr_snap = @sforce.gather_metadata.map {|obj| 
      SfOpticon::Schema::SfObjects.map_fields_from_sf(obj)
    }
    diff = SfOpticon::Diff.diff(sf_objects, curr_snap)
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
    @sforce.retrieve(:manifest => manifest, :extract_to => dir)

    # Now we replay the changes into the repo and the database
    diff.each do |change|
      @log.info { "DIFF: #{change[:type]} - #{change[:object][:full_name]}" }

      case change[:type]
      when :delete
        scm.delete(change[:object][:file_name])
        sf_objects
          .find_by_sfobject_id(change[:object][:sfobject_id])
          .delete()

      when :rename
        scm.rename(change[:old_object][:file_name], change[:object][:file_name])
        sf_objects
          .find_by_sfobject_id(change[:old_object][:sfobject_id])
          .clobber(change[:object])

      when :add
        scm.add("#{dir}/#{change[:object][:file_name]}",change[:object][:file_name])
        sf_objects << change[:object]

      when :modify
        scm.modify("#{dir}/#{change[:object][:file_name]}",change[:object][:file_name])
        sf_objects
          .find_by_sfobject_id(change[:object][:sfobject_id])
          .clobber(change[:object])

      end
    end
    save!
    FileUtils.remove_entry_secure(dir)

    @log.info { "Complete." }
    diff
  end

  def init_production
    scm.create_repo
  end

  def init_branch
  end
end