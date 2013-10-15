##
# Class for managing branches. 
#
# All branch operations (merge etc.) should be performed
# through this branch class. This class belongs to 
# {SfOpticon::Environment}.
#
# @author Ryan Parr
#
# @attr [String] name 
#    The name of the branch. This may not reflect the
#    name of the Salesforce environment as this could
#    be an integration branch.
# @attr [String] local_path
#    This is the path to the branch on the local machines.
# @attr [SfOpticon::Scm] scm
#    The underlying scm interface object.
class SfOpticon::Branch < ActiveRecord::Base
	attr_accessible :name,
	                :local_path,
	                :scm
	belongs_to :environment

	##
	# Creates a new branch and returns the branch object.
	#
	# @option opts [String] :name 
	#    The name of the branch. 
	# @option opts [SfOpticon::Branch] :source
	#    The branch from which to create this branch
	# @return [SfOpticon::Branch]
	def self.make_branch(opts = {})
		unless opts.has_key? :name
			raise ArgumentError ":name is required"
		end

		unless opts.has_key? :source
			raise ArgumentError ":source is required"
		end

		
	end
end