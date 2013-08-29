require 'git'
require 'octokit'
require 'fileutils'

class Opticon::Scm::Github
	attr_accessor :octo, :repo, :config, :repo_path, :path
	

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

	def git_init
		@log.debug { "Initializing git directory at #{@path}" }
		Git.init(@path)
	end

	def repo_exists?
		!!@repo
	end

	def create_repo
		@log.info { "Creating repository #{@repo_path}" }
		@log.debug { "RepoExists: #{repo_exists?}"}
		if repo_exists?
			@log.debug { "Repository #{@repo_path} found." }
		else
			@log.debug { "Executing @octo.create_repo('#{@config.repo}')"}
			@repo = @octo.create_repo(@config.repo)
			create_master
		end

		@repo
	end

	# We have to create a file in order to generate
	# the initial master branch
	def create_master(path = @path)
		@log.info { "Creating master branch at #{path} for #{path} "}

		FileUtils.rm_rf(path)
		FileUtils.mkdir_p(path)
		@git = git_init
		
		File.open("#{@path}/README", 'w') do |f|
			f.write("Repository init at #{DateTime.now}")
		end
		@git.add(:all => true)
		@git.commit('Repository Init')

		# Finalize
		@git.add_remote('origin', @repo_url)
		@git.push('origin')		
	end

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

	def add
		@git.add(:all => true)
	end

	def delete
	end

	def commit(message = nil)
		@git.commit(message)
		@git.push('origin')
	end
end