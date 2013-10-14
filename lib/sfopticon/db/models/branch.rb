class SfOpticon::Branch < ActiveRecord::Base
	attr_accessible :name
	belongs_to :environment

	def make_int_branch
		new(environment)
	end

	def merge_in(src_branch)
		scm = SfOpticon::Scm.new(src_branch.name)
	end
end