require 'git'
require 'octokit'

# @note Please see {SfOpticon::Scm::Base} for documentation
module SfOpticon::Scm::Github 
  include SfOpticon::Scm::Base
  attr_reader :git

  ##
  # Creates a remote repository on GitHub
  #
  # The repository will 'auto_init', meaning once it's created it will
  # create its own master branch.
  #
  # @param name [String] The name of the remote repository on GitHub
  def self.create_remote_repository(name, opts = {})
    config = SfOpticon::Settings.scm.dup
    config.options.merge! opts

    # Reset this option explicitly just in case someone mucks with it
    config.options['auto_init'] = true
    SfOpticon::Logger.info { "Creating repository #{name}" }

    ##Octokit to create the repo on Github
    octo = Octokit::Client.new :login => config.username,
                               :password => config.password

    # If the remote repository already exists we need to bomb out
    if octo.repository? Octokit::Repository.from_url "#{config.url}/#{name}"
      raise SfOpticon::Scm::RepositoryFoundException.new(
        "A repository by the name of #{name} already exists!")
    end

    # Create the remote repository, already init'd
    octo.create_repo(name, config.options)
  end

  ##
  # Initializes the branch with a README.md update
  def make_branch
    @log.info { "Creating branch #{name}" }
    clone
    File.open(File.join(local_path, 'README.md'), 'w') do |f|
      f.puts("Initializing branch #{name} at #{DateTime.now}")
    end
    add_changes
    commit("Branch initialization")
    push
  end

  ##
  # Creates an integration branch. These will be a branch of *this*
  # branch and will be a destination for merging from some other branch.
  # It is from these branches that manifests will be generated and
  # deployed.
  #
  # @param ib_name [String] The name of the integration branch
  def make_integration_branch(ib_name)
    # First just ensure that we're on the correct branch
    init

    # Now we want to create a new branch from this and check it out
    git.branch(ib_name).checkout
  end

  ##
  # Performs a merge from any branch to the current branch
  # 
  # @param branch [String] The branch to merge in
  def merge(branch)
    @log.info { "Merging branch #{branch} into #{name}"}
    merge_result = git.merge(branch)
    @log.info { "Merge result: #{merge_result}" }
  end

  ##
  # Calculates the changes on a branch since its inception. This is only done
  # for integration branches, which are a throw-away and which we will be on
  # at the time. We need the other_env to look up additions in the sf_objects
  # so we have enough information for a manifest.
  # 
  # @param other_env [SfOpticon::Environment] The environment we're merging in
  # @return changes [Hash] A hash with 2 keys, :added and :deleted, which are
  #    arrays of sf_objects
  def calculate_changes_on_int(other_env)
    changes = { :added => [], :deleted => [] }
    git.diff(name, git.current_branch).each do |commit|
      case commit.type
      when 'modified', 'new'
        changes[:added].push(other_env.sf_objects.find_by_file_name(commit.path))
      when 'deleted'
        changes[:deleted].push(environment.find_by_file_name(commit.path))
      end
    end

    changes
  end  

  ##
  # Clones the repo_url into the local path and switches to the branch
  def clone
    @log.info { "Cloning repository to #{local_path}"}
    @git = Git.clone(auth_url, local_path)
    git.branch(name).checkout
  end

  ##
  # Instantiate the local repo objects
  def init
    @log.info { "Init'ing local repository #{local_path}" }
    @git = Git.init(local_path)
    git.branch(name).checkout
  end

  ##
  # Recursively adds all changes to staging
  def add_changes
    @log.info { "Recursively adding all changes to staging" }
    git.add(:all => true)
  end

  ##
  # Commits all staged changes to local repository.
  #
  # @param message [String] The commit message (required)
  # @param author [String] The author of the commit (optional)
  # @param author_email [String] The author email (optional)
  def commit(message, author = nil, author_email = nil)
    @log.info { "Committing all staged changes to local repository" }
    if author
      git.config('user.name', author)
    end

    if author_email
      git.config('user.email', author_email)
    end

    git.commit(message)
  end

  ##
  # Pushes changes to remote
  def push
    @log.info { "Pushing to origin" }
    git.push('origin', "#{name}:#{name}")
  end
end
