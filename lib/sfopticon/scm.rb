# This class provides a sort of factory for the actual SCM adapter
#
# (see #SfOpticon::Scm::Base)
class SfOpticon::Scm
	def self.adapter
		adapter_lib = File.dirname(__FILE__) + '/scm/'  \
		            + SfOpticon::Settings.scm.adapter \
		            + '.rb'
		load adapter_lib
		"SfOpticon::Scm::#{SfOpticon::Settings.scm.adapter.capitalize}".constantize		
	end

	def self.new(*args)
		adapter.new(*args)
	end
end