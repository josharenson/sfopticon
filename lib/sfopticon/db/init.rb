ActiveRecord::Base.establish_connection(SfOpticon::Settings.database)

require 'sfopticon/db/models/environments'
require 'sfopticon/db/models/sf_objects'
require 'sfopticon/db/models/branches.rb'
require 'sfopticon/db/models/integration_branches.rb'
