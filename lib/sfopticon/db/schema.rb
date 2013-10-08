class SfOpticon
	module Schema
		require 'sfopticon/db/models/environments'
		require 'sfopticon/db/models/sf_objects'
	end

	conn = ActiveRecord::Base.establish_connection(SfOpticon::Settings.database)

  if not conn.connected?
    adapter = SfOpticon::Settings.database.adapter
    database = SfOpticon::Settings.database.database
    abort "Could not connect to local database. Ensure a " + adapter + " is running with a database named " + database
  end

  unless ActiveRecord::Base.connection.table_exists? :environments
		ActiveRecord::Schema.define do
			create_table "environments", :force => true do |t|
				t.string   "name", :unique => true, :null => false
				t.string   "username"
				t.string   "password"
				t.boolean  "production"
			end
		end	
	end

	unless ActiveRecord::Base.connection.table_exists? :sf_objects
		ActiveRecord::Schema.define do		
			create_table "sf_objects", :force => true do |t|
				t.string   "created_by_id"
				t.string   "created_by_name"
				t.datetime "created_date"
				t.string   "file_name"
				t.string   "full_name"
				t.string   "sfobject_id"
				t.string   "last_modified_by_id"
				t.string   "last_modified_by_name"
				t.datetime "last_modified_date"
				t.string   "manageable_state"
				t.string   "object_type"
				t.string   "namespace_prefix"
				t.integer  "environment_id"
			end


			add_index "sf_objects", ["environment_id"], :name => "index_sf_objects_on_environment_id"
			add_index "sf_objects", ["file_name"], :name => "index_sf_objects_on_file_name"
		end
	end
end
