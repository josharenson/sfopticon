class Opticon
	module Schema
		require 'opticon/db/models/environments'
		require 'opticon/db/models/changes'	
		require 'opticon/db/models/sf_objects'
		require 'opticon/db/models/changesets'
	end

	ActiveRecord::Base.establish_connection(Opticon::Settings.database)

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

	unless ActiveRecord::Base.connection.table_exists? :changes
		ActiveRecord::Schema.define do
			create_table "changes", :force => true do |t|
				t.string   "sfobject_id"
				t.string   "full_name"
				t.string   "file_name"
				t.string   "object_type"
				t.string   "last_modified_by_name"
				t.datetime "last_modified_date"
				t.string   "change_type"
				t.integer  "changeset_id"
			end

			add_index 'changes', ['full_name'], :name => 'index_changes_on_full_name'
			add_index 'changes', ['sfobject_id'], :name => 'index_changes_on_sfobject_id'
			add_index 'changes', ['changeset_id'], :name => 'index_changes_on_changeset_id'
		end
	end

	unless ActiveRecord::Base.connection.table_exists? :changesets
		ActiveRecord::Schema.define do
			create_table "changesets", :force => true do |t|
				t.integer "environment_id"
				t.datetime "created_at", :null => false
			end

			add_index 'changesets', ['environment_id'], :name => 'index_changesets_on_environment_id'
		end
	end
end
