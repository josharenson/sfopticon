class AddToEnvironments < ActiveRecord::Migration
  def change
  	add_column :environments, :branch_id, :integer
  end
end
