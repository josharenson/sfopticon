# This class provides a sort of factory for the actual SCM adapter
#
# SCM adapters should accept named arguments in the constructor
# which add to and override the configuration under the SCM options
# in the configuration YAML.
#
# SCM adapters should all define the following methods:
# repo_exists?::
# create_repo:: This will create a new remote repository
# delete_repo:: Deletes the remote repository
# create_branch(name):: Forks from HEAD
# delete_branch(name):: Deletes named branch
# add:: Recursive addition of all changes to the working copy
# delete(listOfFiles[]):: Deletion of specific files from the working copy
# commit:: Commits, and pushes to remote if necessary
#

class SfOpticon::Scm
	def self.new(*args)
		adapter_lib = File.dirname(__FILE__) + '/scm/'  \
		            + SfOpticon::Settings.scm.adapter \
		            + '.rb'
		load adapter_lib
		klass = "SfOpticon::Scm::#{SfOpticon::Settings.scm.adapter.capitalize}".constantize
		klass.new(*args)
	end
end