require 'metaforce'
require 'fileutils'

class Opticon::Schema::Environment < ActiveRecord::Base
  validates_uniqueness_of :name, :message => "This organization is already configured."
  attr_accessible :name, 
                  :username, 
                  :password, 
                  :production
                
  has_many :sf_objects, :dependent => :destroy
  has_many :changesets, :dependent => :destroy

  def initialize(*args)
    @log = Opticon::Logger
    @config = Opticon::Settings.salesforce
    super(*args)
  end

  def remove
    # We skip the instantiation and go straight to single
    # statement deletion
    sf_objects.delete_all
    changesets.delete_all

    # Discard the org contents.
    begin
      FileUtils.remove_dir("#{Opticon::Settings.scm.local_path}/#{name}")
    rescue Errno::ENOENT
      # We pass if the directory is already gone
    end

    delete
  end

  def client
    unless @client
        Metaforce.configure do |c|
          c.host = 'test.salesforce.com' unless self[:production]
          c.log = Opticon::Logger
        end

        @client = Metaforce::Metadata::Client.new :username => self[:username], 
                                                  :password => self[:password]
    end

    return @client
  end

  #### Init the repository
  # If this is the initial setup of the production system we'll want an empty
  # repository. The repository will need to be configured on the remote server
  # and empty.
  # 
  # If this isn't a production org, then we're going to want to branch from the
  # production org.
  def init
    @scm = Opticon::Scm.new(:repo => name)
    scanner = Opticon::Scan.new(self)
    scanner.snapshot    

    if production
      init_production
      retrieve_full_org
    else
      init_branch
    end
  end

  def retrieve_full_org
    manifest = self.class.generate_manifest(sf_objects)
    manifest.keys.each do |type|
      @log.debug("Retrieving #{type}")
    end
  end

  def init_production
    @scm.create_repo
  end

  def init_branch
  end

  def self.generate_manifest(object_list)
    manifest = {}
    object_list.each do |sf_object|
      sym = sf_object[:object_type].snake_case.to_sym
      if not manifest.has_key? sym
        manifest[sym] = []
      end

      manifest[sym].push(sf_object[:full_name])
    end
    return manifest
  end    

  def self.manifest(object_list)
    Metaforce::Manifest.new(self.generate_manifest(object_list)).to_xml    
  end

  ## Generates a package.xml string of all objects on org
  def snapshot_manifest
    Opticon::Schema::Environment.manifest(sf_objects)
  end

  ## Generates a destructuve package.xml based on the changeset
  def destructive_manifest
    Opticon::Schema::Environment.manifest(changes.where("change_type = 'DEL'"))
  end

  ## Generates an additive package.xml based on the changeset
  def productive_manifest
    Opticon::Schema::Environment.manifest(changes.where("change_type = 'ADD' or change_type = 'MOD'"))
  end  
end
