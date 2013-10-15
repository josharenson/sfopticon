require 'git'
require 'octokit'
require 'fileutils'

# @note Please see {SfOpticon::Scm::Base} for documentation
class SfOpticon::Scm::Github < SfOpticon::Scm::Base
  #@!attribute repo_url
  #  @return [String] The full URL to the remote repository
  attr_accessor :repo_url
  attr_reader :username
  @password

  def self.create_remote_repo(name, opts = {})
    SfOpticon::Logger.info { "Creating remote repository #{name}" }
    repo = self.new(name, opts)
    repo.create_repo

    repo
  end

  def self.create_branch(src,name)
    SfOpticon::Logger.info { "Creating branch #{name} from #{src.repo_name}"}
    repo = self.new(name)
    repo.create_branch(src.repo_url)

    repo
  end

  def initialize(name, opts = {})
    @repo_name = name
    @log = SfOpticon::Logger

    ## Merge in any specified properties
    @config = SfOpticon::Settings.scm
    @config.deep_merge! opts

    # Make sure that our local_path exists
    unless Dir.exist? @config.local_path
      FileUtils.mkdir_p @config.local_path
    end    

    ## Entry point for all things github
    @username = @config.username
    @password = @config.password
    @octo = Octokit::Client.new :login => @username,
                                :password => @password

    # We have to insert the username/password into the URL for
    # adding the remote
    auth_url = @config.url.gsub /(https?:\/\/)(.*)/,
                                "\\1#{@config.username}:#{@config.password}@\\2"

    @repo_url = "#{auth_url}/#{@repo_name}"
    @repo_path = Octokit::Repository.from_url @repo_url
    begin
      @repo = @octo.repository? @repo_path
    rescue Exception => e
      @log.error { "An exception was raised getting the repository from OctoKit: #{e.message}" }
      raise e
    end

    ## Local path
    @local_path = "#{@config.local_path}/#{@repo_name}"

    if Dir.exist? @local_path
      @git = Git.open(@local_path)
    end
  end

  def add_changes
    @git.add(:all => true)
  end

  def commit(message, author = nil, author_email = nil)
    if author
      @git.config('user.name', author)
    end

    if author_email
      @git.config('user.email', author_email)
    end

    @git.commit(message)
  end

  def push(local_branch = nil, remote_branch = nil)
    if local_branch and remote_branch
      @git.push('origin', "#{local_branch}:#{remote_branch}")
    elsif local_branch
      @git.push('origin', local_branch)
    else
      @git.push('origin')
    end
  end

  def repo_exists?
    !!@repo
  end

  # Creates a remote repository on GitHub
  def create_repo
    @config.options['auto_init'] = true
    @log.info { "Creating repository #{@repo_path}" }

    if repo_exists?
      @log.debug { "Repository #{@repo_path} found"  }
    else
      @log.debug { "Executing @octo.create_repo('#{@repo_name}')"}
      @repo = @octo.create_repo(@repo_name, @config.options)
      @git = Git.clone(@repo_url, @local_path)
      update_readme("Production Master")
    end

    @repo
  end

  ## Creates a branch
  def create_branch(repo_url)
    @log.info { "Creating branch #{@repo_name}" }
    @git = Git.clone(repo_url, @local_path)

    # For some reason I can't update an existing file in the in_branch block.
    # Additionally, this block doesn't actually commit. After the block is complete
    # you still have to checkout the branch.
    @git.branch(@repo_name).in_branch("Creating branch #{@repo_name}") do
      update_readme("Branch #{@repo_name}")
    end
    checkout_res = @git.checkout(@repo_name)
    @log.debug { "Checkout: " + checkout_res }
    push(@repo_name,@repo_name)
  end

  # Creates the master branch on Github by adding a README with
  # the timestamp of creation
  def create_master(path = @local_path)
    @log.info { "Creating master branch at #{path} for #{path} "}

    FileUtils.rm_rf(path)
    FileUtils.mkdir_p(path)
    @git = Git.init(path)

    update_readme("Production Master")
    add_changes
    commit('Repository Init')

    # Finalize
    @git.add_remote('origin', @repo_url)
    push
  end

  def update_readme(msg = nil)
    @log.debug { "Updating readme file at #{@local_path} #{msg}"}
    File.open("#{@local_path}/README.md", 'w') do |f|
      f.puts("Init at #{DateTime.now}")
      if msg
        f.puts("")
        f.puts(msg)
      end
    end

    return true
  end
end
