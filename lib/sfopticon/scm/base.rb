# @abstract Abstract/Base class for all Scm adapters.
class SfOpticon::Scm::Base

	##
	# Adds a file to the local repository.
	#
	# @param src [String] The path to the local file
	# @param dst [String] The destination for the file in the local repo,
	#    relative to the base of the repository.
	def add_file(src,dst)
		raise NotImplementedError
	end

	##
	# Clobbers a file in the local repository with the supplied 
	# src file. 
	#
	# @param src [String] The path to the local file
	# @param dst [String] The destination for the file in the local repo,
	#    relative to the base of the repository.
	def clobber_file(src,dst)
		raise NotImplementedError
	end

	##
	# Deletes a file from the local repository.
	#
	# @param path [String] The path to the file, relative to the base of the 
	#    repository, in the local repo.
	def delete_file(path)
		raise NotImplementedError
	end

	##
	# Renames a file in the local repository.
	#
	# @param src [String] The path to the file in the local repo, relative
	#    to the base of the repository
	# @param dst [String] The new path to the file in the local repo, relative
	#    to the base of the repository
	def rename_file(src, dst)
		raise NotImplementedError
	end

	##
	# Performs a commit. For distributed SCM systems this should
	# commit locally, and allow the push to origin to happen with
	# the {#push} method. For non-distributed SCM systems this should
	# perform each actual commit to remote.
	#
	# @param message [String] The commit message (required)
	# @param author  [String] The commit author name (optional)
	# @param author_email [String] The commit authors email (optional)
	def commit(message, author = nil, author_email = nil)
		raise NotImplementedError
	end

	##
	# Performs a push for distributed SCM systems. Non-distributed systems
	# like Subversion should make this a no-op, and perform all commits
	# in the {#commit} method.
	#
	def push()
		raise NotImplementedError
	end

	##
	# Creates the remote repository. 
	#
	# @param name [String] The name of the repository to create.
	def create_remote_repo(name)
		raise NotImplementedError
	end

	##
	# Creates a branch from HEAD, which represents the production Salesforce org
	#
	# @param name [String] The name of the branch to create.
	def create_branch(name)
		raise NotImplementedError
	end
end