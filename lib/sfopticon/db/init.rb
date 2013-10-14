ActiveRecord::Base.establish_connection(SfOpticon::Settings.database)

require 'sfopticon/db/models/environments'
require 'sfopticon/db/models/sf_objects'