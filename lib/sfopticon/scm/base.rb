# @baseclass Abstract/Base class for all Scm adapters.
class SfOpticon::Scm::Base
	# @todo Actually implement the file-based methods which will be nearly
	#     universal across SCM implementations

	##
	# Adds a file to the local repository. 
	# @note Reraises IO exceptions.
	#
	# @param src [String] The path to the local file
	# @param dst [String] The destination for the file in the local repo,
	#    relative to the base of the repository.
	# @return [Boolean] True if successful, false otherwise.
	def add_file(src,dst)
		raise NotImplementedError
	end

	##
	# Clobbers a file in the local repository with the supplied 
	# src file. 
	# @note (see #add_file)
	#
	# @param src [String] The path to the local file
	# @param dst [String] The destination for the file in the local repo,
	#    relative to the base of the repository.
	# @return (see #add_file)
	def clobber_file(src,dst)
		raise NotImplementedError
	end

	##
	# Deletes a file from the local repository.
	#
	# @param path [String] The path to the file, relative to the base of the 
	#    repository, in the local repo.
	# @return (see #add_file)
	def delete_file(path)
		raise NotImplementedError
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
		raise NotImplementedError
	end

	##
	# Adds all changes in the tree to the commit list. For repositories other
	# than Git this will likely be a no-op
	#
	# @return (see #add_file)
	def add_changes()
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
	def push()
		raise NotImplementedError
	end

	##
	# Deletes the repository from the local filesystem and freezes the object. 
	# This method leaves the remote repository fully intact. 
	#
	# @note (see #add_file)	
	#
	# @return (see #add_file)
	def delete_local_repo(repo)
		raise NotImplementedError
	end

	##
	# Creates the remote repository. All configuration is taken from the application
	# configuration, allowing for overrides passed after the name parameter.
	#
	# @param name [String] The name of the repository to create.
	# @param options [Hash] Any values under {SfOpticon::Settings}.scm to override
	# @return [SfOpticon::Scm]
	def self.create_remote_repo(name, options = {})
		raise NotImplementedError
	end

	##
	# Creates a branch from HEAD, which represents the production Salesforce org.
	# All configuration is taken from the application configuration.
	# 
	# @param name [String] The name of the branch to create.
	# @return [SfOpticon::Scm]
	def self.create_branch(name)
		raise NotImplementedError
	end
end