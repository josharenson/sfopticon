class CreateEnvironments < ActiveRecord::Migration
  def change
    create_table :environments, :force => true do |t|
      t.string   "name", :unique => true, :null => false
      t.string   "username"
      t.string   "password"
      t.boolean  "production"

      t.timestamps
    end
  end
end
