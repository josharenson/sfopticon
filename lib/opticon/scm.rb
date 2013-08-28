class Opticon::Scm
	def self.new(*args)
		adapter_lib = File.dirname(__FILE__) + '/scm/'  \
		            + Opticon::Settings.scm.adapter \
		            + '.rb'
		load adapter_lib
		klass = "Opticon::Scm::#{Opticon::Settings.scm.adapter.capitalize}".constantize
		klass.new(*args)
	end
end