class SfOpticon::ChangeMonitor
  class Diff
    def self.diff(orig_snap, new_snap)
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
        puts "#{key} does not exist in new_snap"
        changes.push({:object => orig_snap_ids[key], :type => :delete})
      end

      # Now perform the addition check
      (new_snap_ids.keys - orig_snap_ids.keys).each do |key|
        puts "#{key} does not exist in old_snap"
        puts "Proof: #{orig_snap_ids.has_key? key}"
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
          puts "#{key} has been modified"
          if o_full_name != n_full_name || o_file_name != n_file_name
            puts "#{key} has been renamed"
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
