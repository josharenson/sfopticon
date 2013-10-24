class AddLockToEnvironment < ActiveRecord::Migration
  def change
    add_column :environments, :locked, :boolean
  end
end
