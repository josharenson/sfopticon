class CreateIntegrationBranches < ActiveRecord::Migration
  def change
    create_table :integration_branches do |t|
      t.string "name", :unique => true, :null => false
      t.integer "source_env", :null => false
      t.integer "dest_env", :null => false
      t.string "commit_id", :unique => true
      t.boolean "is_deployed", :default => false

      t.timestamps
    end
  end
end
