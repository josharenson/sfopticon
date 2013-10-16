require 'git'
require 'octokit'

# @note Please see {SfOpticon::Scm::Base} for documentation
module SfOpticon::Scm::Github 
  include SfOpticon::Scm::Base

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
  # Clones the repo_url into the local path and switches to the branch
  def clone
    @log.info { "Cloning repository to #{local_path}"}
    @git = Git.clone(auth_url, local_path)
    @git.branch(name).checkout
  end

  ##
  # Instantiate the local repo objects
  def init
    @git = Git.init(local_path)
    @git.checkout(name)
  end

  ##
  # Recursively adds all changes to staging
  def add_changes
    @log.info { "Recursively adding all changes to staging" }
    @git.add(:all => true)
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
      @git.config('user.name', author)
    end

    if author_email
      @git.config('user.email', author_email)
    end

    @git.commit(message)
  end

  ##
  # Pushes changes to remote
  def push
    @log.info { "Pushing to origin" }
    @git.push('origin', "#{name}:#{name}")
  end
end
