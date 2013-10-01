require 'sfopticon'
require 'fileutils'

RSpec.configure do |c|
	c.treat_symbols_as_metadata_keys_with_true_values = true
end

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}