class Opticon::Schema::Changeset < ActiveRecord::Base
  attr_accessible :id, :created_at
  has_many :changes, :dependent => :destroy
  belongs_to :environment
end