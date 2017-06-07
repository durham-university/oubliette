module Oubliette
  class ExportActor < Oubliette::BaseActor
    attr_accessor :export_file_ids, :export_method, :export_destination, :export_note
    def initialize(user=nil, attributes={})
      super(nil, user, attributes)
      @export_method = @attributes.fetch(:export_method, :store)
      @export_file_ids = @attributes[:export_file_ids]
      @export_destination = @attributes[:export_destination]
      @export_note = @attributes[:export_note]
    end
    
    def export!
      log!("Starting export")
      log!("Export note: #{export_note}") if export_note.present?
      log!("Export user: #{(user || 'none').to_s}")
      log!("Export method: #{export_method}")
      log!("Export destination: #{export_destination}") if export_destination.present?
      log!("Export files: #{export_file_ids.join(', ')}")
      begin
        zip_files && send_zip
      rescue StandardError => e
        log!(e)
      ensure
        finish_export
      end
      !log.errors?
    end
    
    def export_temp_dir
      Oubliette.config.fetch('export_temp_dir', Dir.tmpdir)
    end
    
    def export_temp_path
      @export_temp_path ||= begin
        if export_method == :store && export_destination.present?
          export_destination
        else
          path = nil
          while path.nil? || File.exists?(path)
            path = File.join(export_temp_dir,"oubliette-#{SecureRandom.hex}.zip")
          end
          path
        end
      end
    end
    
    def export_temp_zip
      @export_temp_zip ||= Zip::File.open(export_temp_path, Zip::File::CREATE)
    end
    
    def oubliette_files
      Enumerator.new do |y|
        export_file_ids.each do |file_id|
          begin
            y << Oubliette::PreservedFile.find(file_id)
          rescue StandardError => e
            log!("Error getting file #{file_id}", e)
          end
        end
      end
    end
    
    def zip_files
      used_file_names = {}
      begin
        log!("Zip file: #{export_temp_zip.name}")
        oubliette_files.each do |file|
          log!("Adding file #{file.id}")
          zip_file_name = file.content.original_name || 'file'
          counter = 0
          while zip_file_name.blank? || used_file_names.key?(zip_file_name.downcase)
            m = zip_file_name.match(/^(.*?)(\.[^\.]*)?$/)
            zip_file_name = "#{m[1]}-#{counter += 1}#{m[2]}"
          end
          used_file_names[zip_file_name.downcase] = true
          
          io = DurhamRails::Services::FedoraFileService::FedoraStreamIO.new(file.content)
          
          export_temp_zip.get_output_stream(zip_file_name) do |os|
            IO.copy_stream(io, os)
          end
        end
      rescue StandardError => e
        log!(e)
      ensure
        @export_temp_zip.try(:close)
      end
      !log.errors?
    end
    
    def send_zip
      # TODO: Send zip file based on export_method
      true
    end
    
    def clean_temporary_file
      if @export_temp_zip.present?
        case
        when export_method == :email || self.log.errors?
          log!("Removing zip file")
          File.unlink(@export_temp_zip.name) # .name is the path of the file
        when export_method == :store
          log!("Method is #{export_method}, preserving zip file")
          # do nothing, leave file on disk
        end
      end
    end
    
    def finish_export
      begin
        clean_temporary_file
      rescue StandardError => e
        log!("Error cleaning temporary files", e)
      ensure
        email_notifications
        log!("Export finished")
      end
    end
    
    def email_notifications
      # TODO: Send email notifications
    end
    
  end
end