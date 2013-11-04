class SfOpticon::ChangeMonitor
  class Diff
    ##
    # Generates a basic changeset between to snapshots of the same environment.
    #
    # @param orig_snap 
    # @param new_snap
    def self.snap_diff(orig_snap, new_snap)
      changes = []

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
        @log.info { "Deletion detected: #{orig_snap_ids[key][:full_name]}"}
        changes.push({:object => orig_snap_ids[key], :type => :delete})
      end

      # Now perform the addition check
      (new_snap_ids.keys - orig_snap_ids.keys).each do |key|
        @log.info { "Addition detected: #{new_snap_ids[key][:full_name]}" }
        changes.push({:object => new_snap_ids[key], :type => :add})
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
          @log.info { "#{orig_snap_ids[key][:full_name]} has been modified"
          if o_full_name != n_full_name || o_file_name != n_file_name
            @log.info { "#{orig_snap_ids[key]} has been renamed to #{new_snap_ids[key][:full_name]}"
            changes.push({ :old_object => orig_snap_ids[key],
                           :type => :rename,
                           :object => new_snap_ids[key] })
          else
            changes.push({:object => new_snap_ids[key], :type => :modify})
          end
        end
      end

      # The changes will be sorted by their timestamp
      return changes.sort {|x,y|
        x[:object][:last_modified_date] <=> y[:object][:last_modified_date]
      }
    end
  end
end
