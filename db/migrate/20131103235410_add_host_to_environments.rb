class AddHostToEnvironments < ActiveRecord::Migration
  def change
  	add_column :environments, :host, :string, :default => 'test.salesforce.com'
  end
end
