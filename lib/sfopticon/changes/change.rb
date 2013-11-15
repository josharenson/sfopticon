class SfOpticon::Changes
  attr_reader :sf_object
  def initialize(sf_object, src_dir)
    @sf_object = sf_object
  end

  def last_modified_date
    sfobject[:last_modified_date]
  end

  class Addition < self

  end

  class Modification < self
  end

  class Deletion < self
  end
end