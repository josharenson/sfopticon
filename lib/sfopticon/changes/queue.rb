class SfOpticon::Changes
  class Queue
    @log = SfOpticon::Logger
    @changes = {}
    [:additions, :modifications, :deletions].each {|k| @changes[k] = []}

    ## 
    # This will create the following methods:
    # - additions
    # - add_to_additions
    # - modifications
    # - add_to_modifications
    # - deletions
    # - add_to_deletions
    @changes.keys.each do |k|
      define_method(k) { @changes[k] }
      define_method("add_to_#{k}") {|sfo| 
        @changes[k] << sfo
        @changes[k].sort! {|x,y|
          x.last_modified_date <=> y.last_modified_date
        }
      }
    end

    ##
    # Apply each change in the queue to the dst_dir in order
    # and apply the block. This is for the SCM to commit, or
    # whatever.
    def apply_to_environment(src_dir, dst_dir, &block)
    end
  end
end
