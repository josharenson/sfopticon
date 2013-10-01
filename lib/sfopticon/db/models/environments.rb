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
    super(*args)
  end

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

  def client
    unless @client
        Metaforce.configure do |c|
          c.host = 'test.salesforce.com' unless self[:production]
          c.log = SfOpticon::Logger
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
  # production org instead.
  def init
    @scm = SfOpticon::Scm.new(:repo => name)
    scanner = SfOpticon::Scan.new(self)
    scanner.snapshot    

    if production
      init_production
      retrieve(manifest())   
      @scm.add_changes
      @scm.commit("Initial push of production code")
    else
      init_branch
    end
  end

  # Retrieves the Salesforce Metadata objects according to the Metaforce::Manifest given.
  # If no Metaforce::Manifest is given then it attempts to retrieve the entire org according
  # to the latest snapshot.
  def retrieve(mf)
    mf ||= manifest
    @log.debug { "Retrieving #{mf.keys.join(',')}" }
    @client.retrieve_unpackaged(mf)
           .extract_to(@scm.path)
           .perform    
  end

  def init_production
    @scm.create_repo
  end

  def init_branch
  end

  # Generates a Metaforce::Manifest based on the list of objects
  # given. The objects must match type SfOpticon::Schema::SfObject
  # Params:
  # <object_list>:: Optional parameter. If not provided then it will
  # be the full manifest for this environment.
  def manifest(object_list = nil)
    object_list ||= sf_objects
    mf = {}
    object_list.each do |sf_object|
      sym = sf_object[:object_type].snake_case.to_sym
      if not mf.has_key? sym
        mf[sym] = []
      end

      mf[sym].push(sf_object[:full_name])
    end

    Metaforce::Manifest.new(mf)
  end
end