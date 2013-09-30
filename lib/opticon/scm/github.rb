require 'git'
require 'octokit'
require 'fileutils'

class Opticon::Scm::Github
	attr_accessor :octo, :repo, :config, :repo_path, :path

	# Initialize optionally accepts named options which match the
	# configuration under the scm sectio of the configuration yaml
	def initialize(opts = {})
		raise ArgumentError, "Repository name must be provided" \
			unless opts.has_key? :repo

		@log = Opticon::Logger

		## Merge in any specified properties
		@config = Opticon::Settings.scm
		@config.deep_merge! opts

		## Entry point for all things github
		@octo = Octokit::Client.new :login => @config.username,
			                        :password => @config.password

		## Sure is ugly
		@repo_url = @config.url.split('//') \
								.join("//#{@config.username}:#{@config.password}@") \
								+ "/#{@config.repo}"
		@repo_clone_url = @repo_url + '.git'

		@repo_path = Octokit::Repository.from_url @repo_url
		@repo = @octo.repository? @repo_path

		## Local path
		@path = "#{@config.local_path}/#{@config.repo}"
	end

	# True if remote repo exists.
	def repo_exists?
		!!@repo
	end

	# Creates a remote repository on GitHub
	def create_repo
		@log.info { "Creating repository #{@repo_path}" }
		@log.debug { "RepoExists: #{repo_exists?}"}
		if repo_exists?
			@log.debug { "Repository #{@repo_path} found." }
		else
			@log.debug { "Executing @octo.create_repo('#{@config.repo}')"}
			@repo = @octo.create_repo(@config.repo, @config.options)
			create_master
		end

		@repo
	end

	# Delete's the Github repository
	def delete_repo
		@log.info { "Deleting repository #{@repo_path}" }
		unless repo_exists?
			@log.debug { "Repository #{@repo_path} not found"}
			true
		else
			@octo.delete_repo(@repo_path)
		end

		@repo = false
	end

	# Recursively adds all changes to the index
	def add_changes
		@git.add(:all => true)
	end

	# Deletes a file (or list of files) from the local working
	# directory
	# Params:
	#  file | [list,of,files]
	def delete(file)
		fileList = if file.kind_of? Array
			file
		else
			[file]
		end
		@git.rm()
	end

	# Commit's all indexed changes and pushes to the Github
	# repository
	def commit(message = nil)
		@git.commit(message)
		@git.push('origin')
	end

	private

	# Git initializes the local repo directory
	def init #:doc:
		@log.debug { "Initializing git directory at #{@path}" }
		Git.init(@path)
	end

	# Creates the master branch on Github by adding a README with
	# the timestamp of creation
	def create_master(path = @path) #:doc:
		@log.info { "Creating master branch at #{path} for #{path} "}

		FileUtils.rm_rf(path)
		FileUtils.mkdir_p(path)
		@git = init
		
		File.open("#{@path}/README", 'w') do |f|
			f.write("Repository init at #{DateTime.now}")
		end
		add_changes
		@git.commit('Repository Init')

		# Finalize
		@git.add_remote('origin', @repo_url)
		@git.push('origin')		
	end

end