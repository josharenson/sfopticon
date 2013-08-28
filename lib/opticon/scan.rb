require 'extlib'

class Opticon::Scan
	def initialize(env, type = nil)
		@env = env
		@client = env.client
		@log = Opticon::Logger
		@type = type
	end

	def snapshot
		## Env has to have it's current sf_objects wiped out
		@log.info("Deleting all sfobjects for #{@env.name}")
		Opticon::Schema::SfObject.where(:environment_id => @env.id).delete_all()

		@log.info("Deleting logged changes for #{@env.name}")
		Opticon::Schema::Changeset.where(:environment_id => @env.id).destroy_all()

		## Determine the types we'll list. This includes all top-level
		## items and their children. Some children won't be available,
		## so we just skip them.
		gather_types
		gather_metadata
		
		Opticon::Schema::SfObject.transaction do
			@sfobjects.each do |o|
				@env.sf_objects << Opticon::Schema::SfObject.create(o)
			end
			@env.save!
		end
	end

	def changeset
		gather_types
		gather_metadata

		orig = nil
		if @type
			@log.info("Fetching only sf_objects of type #{@type}")
			orig = @env.sf_objects.where("object_type = ?", @type)
			puts "Fetched #{orig.size} objects"
		else
			orig = @env.sf_objects
		end
		@changes = Opticon::Diff.diff(orig, @sfobjects)

		Opticon::Schema::Changeset.transaction do
			@changeset = Opticon::Schema::Changeset.new
			@changeset.environment = @env				
			@changes.each do |c|
				change = Opticon::Schema::Change.create_as(c[:object], c[:type])
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
		mg = Opticon::Schema::SfObject

		if(@type)
			@names = [@type]
		end

		@names.each do |item|
			@log.info "Gathering #{item}"
			begin
				for rec in @client.list_metadata item do
					if rec.include?(:full_name) and rec.include?(:last_modified_date)
						rec[:created_date] = Time.parse(rec[:created_date]).utc
						rec[:last_modified_date] = Time.parse(rec[:last_modified_date]).utc
						rec[:sfobject_id] = rec[:id]
						rec[:object_type] = rec[:type]
						rec[:environment_id] = @env[:id]
						@sfobjects.push(mg.map_fields_from_sf(rec))
					end
				end
			rescue
				@log.warn "#{item} failed to gather"
			end
		end
		return @sfobjects
	end

	def gather_types
		@names = []
		@client.describe[:metadata_objects].each do |item|
			@names.push item[:xml_name] unless @names.include? item[:xml_name]

			if item[:child_xml_names].kind_of?(Array)
				item[:child_xml_names].each do |c|
					unless c.nil?
						@names.push c unless @names.include? c
					end 
				end
			end
		end
		return @names		
	end
end