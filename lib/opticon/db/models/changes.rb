class Opticon::Schema::Change < ActiveRecord::Base
  attr_accessible :sfobject_id,
                  :full_name, 
                  :file_name,
                  :object_type,
                  :last_modified_by_name,
                  :last_modified_date,
                  :change_type
  belongs_to :changeset
  belongs_to :sf_object, :foreign_key => :sfobject_id, :primary_key => :sfobject_id
  
  def from_sf_object(object)
    self[:sfobject_id] = object[:sfobject_id] || object[:id]
    self[:full_name] = object[:full_name]
    self[:file_name] = object[:file_name]
    self[:object_type] = object[:type] || object[:object_type]
    self[:last_modified_by_name] = object[:last_modified_by_name]
    self[:last_modified_date] = object[:last_modified_date]
  end
  
  def self.create_add(object)
    self.create_as(object, 'ADD')
  end
  
  def self.create_mod(object)
    self.create_as(object, 'MOD')
  end
  
  def self.create_delete(object)
    self.create_as(object, 'DEL')
  end

  def self.create_as(object, type)
    c = self.new
    c.from_sf_object(object)
    c.change_type = type
    c.save!
    c
  end
end
