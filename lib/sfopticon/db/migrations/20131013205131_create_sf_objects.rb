class CreateSfObjects < ActiveRecord::Migration
  def change
	create_table :sf_objects, :force => true do |t|
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

	add_index :sf_objects, ["environment_id"], :name => "index_sf_objects_on_environment_id"
	add_index :sf_objects, ["file_name"], :name => "index_sf_objects_on_file_name"  	
  end
end
