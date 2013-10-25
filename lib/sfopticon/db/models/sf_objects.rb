class SfOpticon::SfObject < ActiveRecord::Base
  belongs_to :environment
  @field_listing = %w(created_by_id created_by_name created_date namespace_prefix
                      file_name full_name sfobject_id last_modified_by_id
                      last_modified_by_name last_modified_date
                      manageable_state object_type)
  @field_listing.each { |f| attr_accessible f.to_sym }

  def copy_from_sf(sfobject)
    self.assign_attributes(SfOpticon::SfObject.map_fields_from_sf(sfobject),
                           :without_protection => true)
  end

  def clobber(sfobject)
    self.assign_attributes(sfobject, :without_protection => true)
  end

  def self.map_fields_from_sf(sfobject)
    sfcopy = sfobject.clone
    sfcopy[:created_date] = Time.parse(sfcopy[:created_date]).utc
    sfcopy[:last_modified_date] = Time.parse(sfcopy[:last_modified_date]).utc
    sfcopy[:sfobject_id] = sfcopy[:id]
    sfcopy[:object_type] = sfcopy[:type]
    sfcopy.delete(:id)
    sfcopy.delete(:type)

    sfcopy
  end

  ## Some helper methods
  ###
  def dirname
    File.dirname(file_name)
  end

  def basename
    File.basename(file_name)
  end

  def fullpath
    File.join(environment.branch.local_path, file_name)
  end

  ##
  # Returns the list of files related to this object. For example,
  # all Apex types have an associated <file_name>-meta.xml file
  # that needs to be copied and deployed along side the object.
  def fileset
    Dir.glob("#{fullpath}*")
  end
end
