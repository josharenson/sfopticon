require 'sfopticon/db/models/environments'
require 'sfopticon/db/models/sf_objects'

class SfOpticon::Schema
	ActiveRecord::Base.establish_connection(SfOpticon::Settings.database)
end