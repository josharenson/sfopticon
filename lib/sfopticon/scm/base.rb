require 'fileutils'

class SfOpticon::Scm::RepositoryFoundException < Exception; end

# @abstract Somewhat abstract base module for all Scm adapters.
#
# @note All SCM adapters should include this module to receive the free
#    methods.
module SfOpticon::Scm::Base
	##
	# Creates the remote repository. All configuration is taken from the application
	# configuration, allowing for overrides passed after the name parameter.
	#
	# @param name [String] The name of the repository to create.
	# @param options [Hash] Any values under {SfOpticon::Settings}.scm to override
	# @return [SfOpticon::Scm]
	def self.create_remote_repository(name, options = {})
		raise NotImplementedError
	end

	##
	# Clone to retrieve the remote repository.
	def clone
		raise NotImplementedError
	end

	##
	# Instantiates the local repo
	def init
		raise NotImplementedError
	end

	##
	# SfOpticon::Settings.scm
	#
	# @return [SfOpticon::Settings.scm]
	def config
		SfOpticon::Settings.scm
	end

	##
	# @return [String] The repository URL with authentication information
	#    embedded
	def auth_url
		url = config.url.gsub /(https?:\/\/)(.*)/,
			"\\1#{config.username}:#{config.password}@\\2"

		prod = SfOpticon::Environment.find_by_production(true)
		"#{url}/#{prod.name}"
	end

	##
	# @return [String] Full path to the local repository.
	def local_path
		File.join(config.local_path, name)
	end

	##
	# Calculates the changes on our integration branch.
	# 
	def calculate_changes_on_int
		raise NotImplementedError
	end

	##
	# Adds a file to the local repository. 
	# @note Reraises IO exceptions.
	#
	# @param src [String] The path to the local file
	# @param dst [String] The destination for the file in the local repo,
	#    relative to the base of the repository.
	# @return [Boolean] True if successful, false otherwise.
	def add_file(src,dst)
		base_path = File.dirname(src)

		unless Dir.exist? base_path
			FileUtils.mkdir_p(base_path)
		end

		FileUtils.cp(src, File.join(local_path, dst))
	end

	##
	# Clobbers a file in the local repository with the supplied 
	# src file. This exists because SCM systems such as ClearCase will 
	# require that you checkout a file prior to editing it.
	# @note (see #add_file)
	#
	# @param src [String] The path to the local file
	# @param dst [String] The destination for the file in the local repo,
	#    relative to the base of the repository.
	# @return (see #add_file)
	def clobber_file(src, dst)
		add_file(src, dst)
	end

	##
	# Deletes a file from the local repository.
	#
	# @param path [String] The path to the file, relative to the base of the 
	#    repository, in the local repo.
	# @return (see #add_file)
	def delete_file(path)
		FileUtils.remove_entry_secure(File.join(local_path, path))
	end

	##
	# Renames a file in the local repository.
	# @note (see #add_file)	
	#
	# @param src [String] The path to the file in the local repo, relative
	#    to the base of the repository
	# @param dst [String] The new path to the file in the local repo, relative
	#    to the base of the repository
	# @return (see #add_file)
	def rename_file(src, dst)
		FileUtils.move(File.join(@local_path, src), File.join(@local_path, dst))
	end

	##
	# Deletes the repository from the local filesystem and freezes the object. 
	# This method leaves the remote repository fully intact. 
	#
	# @note (see #add_file)	
	#
	# @return (see #add_file)
	def delete_local_repo
		FileUtils.remove_entry_secure(@local_path)
		freeze
	end

	##
	# Adds all changes in the tree to the commit list. For repositories other
	# than Git this will likely be a no-op
	#
	# @return (see #add_file)
	def add_changes
		raise NotImplementedError
	end

	##
	# Performs a commit. For Git this will commit locally, and allow the 
	# push to origin to happen with the {#push} method. For non-distributed 
	# SCM systems this should perform each actual commit to remote.
	# @note For Git, {#add_changes} will need to have been executed for this
	#    to have effect.
	#
	# @param message [String] The commit message (required)
	# @param author  [String] The commit author name (optional)
	# @param author_email [String] The commit authors email (optional)
	# @return (see #add_file)
	def commit(message, author = nil, author_email = nil)
		raise NotImplementedError
	end

	##
	# Performs a push for distributed SCM systems. Non-distributed systems
	# like Subversion should make this a no-op, and perform all commits
	# in the {#commit} method.
	#
	# @return (see #add_file)
	def push
		raise NotImplementedError
	end

	##
	# Returns true if the remote repository exists.
	#
	# @return [Boolean]
	def repo_exists?
		raise NotImplementedError
	end

	##
	# Creates a branch from master, which represents the production Salesforce 
	# org. All configuration is taken from the application configuration.
	# 
	# @param name [String] The name of the branch to create.
	# @return [SfOpticon::Scm]
	def create_remote_branch(name)
		raise NotImplementedError
	end
end
