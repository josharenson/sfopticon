class Opticon
	# Config
	require 'rubygems'
	require 'bundler/setup'

	## Vendor
	require 'active_record'
	require 'active_support/core_ext/hash'
	require 'protected_attributes'
	require 'deep_symbolize'

	## Settings needs to be required before any project local libs
	require 'opticon/settings'
	## There, now go ahead

	require 'opticon/logger'
	require 'opticon/db/schema'
	require 'opticon/scm'
	require 'opticon/scan'
end

## Extend hash for deep_symbolize
class Hash; include DeepSymbolizable; end
