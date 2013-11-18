class SfOpticon::Changes::Diff
  ##
  # Generates a basic changeset between to snapshots of the same environment.
  #
  # @param orig_snap 
  # @param new_snap
  # @return Array A list of the changes between snapshots
  def self.snap_diff(orig_snap, new_snap)
    log = SfOpticon::Logger
    changes = SfOpticon::Changes::Queue.new

    # Make a simple sf id search array to check for adds and deletes
    orig_snap_ids, new_snap_ids = Hash.new, Hash.new
    orig_snap.each do |o|
      orig_snap_ids[o[:sfobject_id]] = o
    end
    new_snap.each do |o|
      new_snap_ids[o[:sfobject_id]] = o
    end

    # And perform the deletion check
    (orig_snap_ids.keys - new_snap_ids.keys).each do |key|
      log.info { "Deletion detected: #{orig_snap_ids[key][:full_name]}"}
      changes.deletions << SfOpticon::Changes::Deletion.new(orig_snap_ids[key])
    end

    # Now perform the addition check
    (new_snap_ids.keys - orig_snap_ids.keys).each do |key|
      log.info { "Addition detected: #{new_snap_ids[key][:full_name]}" }
      changes.additions << SfOpticon::Changes::Addition.new(new_snap_ids[key])
    end

    # Now mods
    (orig_snap_ids.keys & new_snap_ids.keys).each do |key|
      # Last mod times
      o_last_m = orig_snap_ids[key][:last_modified_date]
      n_last_m = new_snap_ids[key][:last_modified_date]

      # Full names and file names to catch renames
      o_full_name = orig_snap_ids[key][:full_name]
      n_full_name = new_snap_ids[key][:full_name]
      o_file_name = orig_snap_ids[key][:file_name]
      n_file_name = new_snap_ids[key][:file_name]

      if o_last_m != n_last_m
        log.info { "Modification detected: #{orig_snap_ids[key][:full_name]}" }
        if o_full_name != n_full_name || o_file_name != n_file_name
          log.warn { "WARNING: Object renames are not able to be handled in the Metadata API. This action will create a new object upon deploy." }
          log.info { "#{orig_snap_ids[key]} has been renamed to #{new_snap_ids[key][:full_name]}" }
          changes.deletions << SfOpticon::Changes::Deletion.new(orig_snap_ids[key])
          changes.additions << SfOpticon::Changes::Addition.new(new_snap_ids[key])
        else
          changes.modifications << SfOpticon::Changes::Modification.new(new_snap_ids[key])
        end
      end
    end

    changes
  end
end
