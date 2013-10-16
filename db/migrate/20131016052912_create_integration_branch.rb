class CreateIntegrationBranch < ActiveRecord::Migration
  def change
    create_table :integration_branches do |t|
    	t.string :name, :null => false
    	t.belongs_to :branch
    	t.integer :dest_branch_id, :null => false

    	t.timestamps
    end
  end
end
