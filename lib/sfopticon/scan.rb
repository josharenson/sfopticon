require 'extlib'

class SfOpticon::Scan
	def initialize(env, type = nil)
		@env = env
		@client = env.client
		@log = SfOpticon::Logger
		@type = type
	end

	def snapshot
		## Env has to have it's current sf_objects wiped out
		@log.info { "Deleting all sfobjects for #{@env.name}" }
		SfOpticon::Schema::SfObject.where(:environment_id => @env.id).delete_all()

		@log.info { "Deleting logged changes for #{@env.name}" }
		SfOpticon::Schema::Changeset.where(:environment_id => @env.id).destroy_all()

		gather_metadata
		
		SfOpticon::Schema::SfObject.transaction do
			@sfobjects.each do |o|
				@env.sf_objects << SfOpticon::Schema::SfObject.create(o)
			end
			@env.save!
		end
	end

	def changeset
		gather_metadata

		orig = nil
		if @type
			@log.info { "Fetching only sf_objects of type #{@type}" }
			orig = @env.sf_objects.where("object_type = ?", @type)
			puts "Fetched #{orig.size} objects"
		else
			orig = @env.sf_objects
		end
		@changes = SfOpticon::Diff.diff(orig, @sfobjects)

		SfOpticon::Schema::Changeset.transaction do
			@changeset = SfOpticon::Schema::Changeset.new
			@changeset.environment = @env				
			@changes.each do |c|
				change = SfOpticon::Schema::Change.create_as(c[:object], c[:type])
				@changeset.changes << change

				case c[:type]
					when :add
						@env.sf_objects.create(c[:object])
					when :delete
						change.sf_object.destroy
					when :modify, :rename
						change.sf_object.destroy
						@env.sf_objects.create(c[:object])
				end
			end
			@changeset.save!
		end
	end

	def gather_metadata
		@sfobjects = []
		mg = SfOpticon::Schema::SfObject

		types = if(@type)
			[@type]
		else
			metadata_types
		end

		types.each do |item|
			@log.info { "Gathering #{item}" }
			begin
				for rec in @client.list_metadata item do
					if rec.include?(:full_name) and rec.include?(:last_modified_date)
						rec[:created_date] = Time.parse(rec[:created_date]).utc
						rec[:last_modified_date] = Time.parse(rec[:last_modified_date]).utc
						rec[:sfobject_id] = rec[:id]
						rec[:object_type] = rec[:type]
						rec[:environment_id] = @env[:id]
						@sfobjects << mg.map_fields_from_sf(rec)
					end
				end
			rescue
				@log.warn { "#{item} failed to gather" }
			end
		end
		@sfobjects
	end

	def metadata_types
		# We've moved to hardcoding the available metadata types
		# in application.yml, rather than going after all of them
		# in every case
		@names = SfOpticon::Settings.salesforce.metadata_types
		@names
	end
end