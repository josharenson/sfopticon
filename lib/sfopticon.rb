class SfOpticon
	# Config
	require 'rubygems'
	require 'bundler/setup'

	## Vendor
	require 'active_record'
	require 'active_support/core_ext/hash'
	require 'protected_attributes'
	require 'deep_symbolize'

	## Settings needs to be required before any project local libs
	require 'sfopticon/settings'
	## There, now go ahead

	require 'sfopticon/logger'
	require 'sfopticon/db/init'
	require 'sfopticon/scm'
	require 'sfopticon/scm/base'
	require 'sfopticon/salesforce'
	require 'sfopticon/diff'
end