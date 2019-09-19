module Oubliette
  class IngestionJob
    include Jobduct::ChannelJob
    include DurhamRails::Channels::ChannelBase
    include DurhamRails::Channels::WithResource
    include Jobduct::WithTempFiles
    include DurhamRails::Retry

    request_reader :content_type, default: 'application/octet-stream'
    request_reader :content_path, :temp_content_path, :original_filename, :ingestion_checksum,
                   :ingestion_log, :note, :tag, :title, :job_tag, :access_groups,
                   :parent_id, :add_to_parent
    variable_accessor :state
    request_reader :notifications
    
    def self.new_channel(params)
      raise "No resource given" unless params[:resource] || params[:resource_id] || params[:parent] || params[:parent_id]
      resource = params[:resource]
      resource ||= find_resource(params[:resource_id]) if params[:resource_id] 
      resource ||= params[:parent] 
      resource ||= find_resource(params[:parent_id]) if params[:parent_id]

      if resource.is_a?(Oubliette::FileBatch)
        params.delete(:resource)
        params.delete(:resource_id)
        params.delete(:parent)

        user = User.find_by_user_key(params[:user])
        raise "User not set" unless user.present?

        preserved_file = Oubliette::PreservedFile.new(
          title: params[:title], 
          status: Oubliette::PreservedFile::STATUS_NOT_CHECKED,
          access_groups: Array.wrap(params[:access_groups] || user.try(:default_access_group))
          )
        preserved_file.current_user = user
        unless preserved_file.valid?
          raise "Invalid file attributes. #{preserved_file.errors.full_messages.join("\n")}"
        end
        preserved_file.save
  
        params[:parent_id] = resource.id
        params[:resource] = preserved_file
        params[:add_to_parent] = true
      else
        params.delete(:parent)
        params[:resource] = resource
      end

      if params[:ingestion_log]
        params[:ingestion_log] = params[:ingestion_log].read if !params[:ingestion_log].is_a?(String)
      end
      if params[:content]
        params[:content_type] ||= params[:content].try(:content_type)
        params[:original_filename] ||= params[:content].try(:original_filename)
        params[:temp_content_path] = self.add_temp_file(params.delete(:content))
      end

      super(params)
    end  

    def run
      unless ingestion_path
        log!(:error, "No content_path given")
        return
      end
      unless user.present?
        log!(:error, "User not set, cannot create a new file batch")
        return
      end
      return unless validate_ingestion_path(ingestion_path)

      return if check_duplicate

      resource.current_user = user

      resource.content ||= ActiveFedora::File.new
      resource.content.content = open_file
      resource.content.mime_type = content_type
      resource.content.original_name = original_filename

      resource.ingestion_log ||= ActiveFedora::File.new
      resource.ingestion_log.content = ingestion_log
      resource.ingestion_log.mime_type = 'text/plain'
      
      resource.title = title
      resource.status = Oubliette::PreservedFile::STATUS_NOT_CHECKED
      resource.note = note
      resource.tag = Array.wrap(tag)
      resource.job_tag = job_tag
      resource.ingestion_date = DateTime.now
      resource.ingestion_checksum = ingestion_checksum

      unless resource.valid?
        log!(:error,"Invalid resource attributes. #{resource.errors.full_messages.join("\n")}")
        return
      end

      success = self.retry(retry_log(self, :warning, "saving content", increasing_delay)) do
        resource.save
      end

      unless success
        log!(:error, "Error saving preserved file") 
        return
      end

      if add_to_parent
        parent = Oubliette::FileBatch.find(parent_id)
        unless parent.ordered_members.map(&:id).include?(resource.id)
          parent.ordered_members << resource
          unless parent.save
            log!(:error, "Unable to save parent")
            return
          end
        else
          log!(:info, "Parent already contains resource")
        end
      end

      self.state = 'post'
      local_call('post_ingestion', {binding_key: 'post_ingestion', resource: resource, content_path: ingestion_path})

      result[:preserved_file] = resource.as_json
      send_notification(notification: 'post_ingest') if notify?('post_ingest')      
    end
    
    def callback(callback)
      if self.state == 'post'
        self.state = 'done'
        result[:preserved_file] = resource.as_json
      end
    end

    def clean
      (self.temp_files ||= []) << temp_content_path if temp_content_path
      super
    end
    
    private

    def check_duplicate
      if job_tag.present?
        duplicate = Oubliette::PreservedFile.find_job_duplicate(job_tag)
        if duplicate.present?
          log!("Found duplicate with job_tag #{job_tag}")
          self.state = 'done'
          result[:preserved_file] = duplicate.as_json
          return true
        end
      end
      false
    end

    def open_file
      File.open(ingestion_path, 'rb')
    end

    def ingestion_path
      content_path || temp_content_path
    end

    def validate_ingestion_path(path)
      ingestion_paths = Array.wrap(Oubliette.config['ingestion_path'])
      return log!(:error, 'Ingestion from disk not supported') && false unless ingestion_paths.any?
      abs_path = File.absolute_path(path)
      ingestion_paths.each do |ingestion_path|
        ingestion_path += File::SEPARATOR unless ingestion_path.ends_with? File::SEPARATOR
        next unless abs_path.start_with?(ingestion_path) && abs_path.length > ingestion_path.length
        return log!(:error, "Ingestion file #{abs_path} doesn't exist") && false unless File.exists?(abs_path)
        return log!(:error, "Ingestion file #{abs_path} is a directory") && false if File.directory?(abs_path)
        return true
      end
      return log!(:error, "Not allowed to ingest from #{path}") && false
    end
    
    def notify?(event)
      notifications == true || Array.wrap(notifications).include?(event)
    end
    
  end
end