class SfOpticon::IntegrationBranch < ActiveRecord::Base
	include SfOpticon::Scm.adapter

	attr_accessible :name


end