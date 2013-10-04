require 'extlib'

class SfOpticon::Scan
	def initialize(env, type = nil)
		@env = env
		@log = SfOpticon::Logger
		@sforce = SfOpticon::Salesforce.new(@env)
		@client = @sforce.client
		@type = type
	end

	def changeset
		@sforce.gather_metadata

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
end