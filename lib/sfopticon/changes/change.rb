class SfOpticon::Changes
  attr_reader :sf_object, :change_type, :src_dir, :dst_dir, :log
  def initialize(sf_object)
    @log = SfOpticon::Logger
    @sf_object = sf_object
    @change_type = self.class.name.split(/::/).last.downcase.to_sym
  end

  def fileset(full_path)
    Dir.glob("#{full_path}*")
  end

  class Addition < self
    def apply(src_dir, dst_dir)
      log.info { "Applying #{sf_object[:file_name]} from #{src_dir} to #{dst_dir}"}
      dst_path = File.join(dst_dir, File.dirname(sf_object[:file_name]))
      log.debug { "dst_path = #{dst_path}"}
      log.debug { "Fileset: #{fileset(File.join(src_dir, sf_object[:file_name])).join(', ')}"}
      unless Dir.exist? dst_path
        FileUtils.mkdir_p dst_path
      end

      FileUtils.cp fileset(File.join(src_dir, sf_object[:file_name])), dst_path
    end
  end

  class Modification < Addition;  end

  class Deletion < self
    def apply(src_dir, dst_dir)
      files = fileset(File.join(dst_dir, sf_object[:file_name]))
      log.info { "Deleting #{files.join(', ')}"}
      FileUtils.rm files
    end
  end
end