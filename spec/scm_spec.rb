require 'spec_helper'

describe SfOpticon::Scm do
	before(:all) do
		# We ensure this is done only once, since the values are
		# merged into the Settings singleton
		@repo_name = "SPEC-OPTICON-Salesforce"
		@scm = SfOpticon::Scm.new(@repo_name)
	end

	def clear_local_path
		FileUtils.rm_rf(@scm.path)
	end

	def create_repo
		unless @scm.repo_exists?
			@scm.create_repo
		end
	end

	def del_repo
		if @scm.repo_exists?
			@scm.delete_repo
			clear_local_path
		end
	end

	context "When the service is remote it" do
		it "should successfully connect" do
			@scm.username.should_not be_nil
		end
	end

	context "When managing repositories on a remote service it" do
		it "should be able to create a remote repository", :create_repo do
			del_repo 
			create_repo
		end

		it "should be able to delete a remote repository", :delete_repo do
			del_repo
		end
	end

	context "When the repository is remote it" do
		it "should be able to create a branch"
		it "should be able to compare 2 branches"
		it "should be able to merge the branch"
	end

	context "Given a checked-out repository it" do
		it "should be able to make local changes"
		it "should be able to commit those changes"
		it "should be able to push those changes to origin"
		it "should be able to list changes between 2 points"
	end
end
