require 'extlib' #<-- provides snake_case

##
# Subclass for a type of change. This is basically just to extract
# the common SCM actions (add_changes, commit, etc) out
# of the execution of each change
#
# Example:
#  change = SfOpticon::Scm::Change::Addition.new
#  change.object = rec
#  change.src_dir = '/tmp/changeset-x881'
#  change.play(scm)
class SfOpticon::Scm::Change
	#@!attribute object 
	#    @return [Hash] The hash record from the snapshot
	#@!attribute old_object
	#    @return [Hash] The old object in the case of a rename
	attr_accessor :object, :old_object, :src_dir

	def initialize(object, old_object)
		@object = object
		@old_object = old_object
	end

	##
	# Plays the change into the SCM
	# @param scm [SfOpticon::Scm] The SCM to play the change into
	def play(scm)
		execute

        scm.add_changes
        scm.commit(commit_message, @object.last_modified_by_name)		

        db_update
	end

	##
	# Returns the commit message specific to this change
	def commit_message
		@commit_message = "#{self.class.name.snake_case.split(/_/)[-1]} by #{@object[:last_modified_by_name]}\n"
		@commit_message = @object.keys.sort.map{|key| "#{key}: #{@object[key]}"}.join("\n")
	end

	##
	# Executes the actual change into the repository
	def execute
		raise NotImplementedError
	end

	##
	# Commits the change to the database
	def db_update
		raise NotImplementedError
	end
end

##
# Handles the addition of files. Adds the src_dir attribute
# for the location of the retrieved files from Salesforce
class SfOpticon::Scm::Change::Addition < SfOpticon::Scm::Change
	#@!attribute src_dir [r]
	#    @return [String] The fully-qualified path to the downloaded files from Salesforce	

	##
	# Copies the file from the src_dir to the SCM
	def execute
		scm.add_file("#{dir}/#{object[:file_name]}",object[:file_name])
	end

	def db_update
	end
end