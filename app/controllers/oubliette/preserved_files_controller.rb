module Oubliette
  class PreservedFilesController < Oubliette::ApplicationController
    include DurhamRails::ModelControllerBase

    before_action :authenticate_start_fixity_check!, only: [:start_fixity_check]
    before_action :authenticate_start_characterisation!, only: [:start_characterisation]
    before_action :set_fixity_check_resource, only: [:start_fixity_check]
    before_action :set_characterisation_resource, only: [:start_characterisation]

    def self.presenter_terms
      [:title, :note, :tag, :status, :check_date, :ingestion_date, :ingestion_log, :preservation_log, :characterisation, :ingestion_checksum, :content]
    end

    def self.form_terms
      [:title, :note, :tag, :content, :ingestion_log, :job_tag]
    end

    def self.resources_paging_sort
      'ingestion_date_dtsi desc'
    end
    
    def index
      @query = params['query']
      super
    end
    
    def create
      duplicate = Oubliette::PreservedFile.find_job_duplicate(params.try(:[],'preserved_file').try(:[],'job_tag'))
      if duplicate.present?
        @resource = duplicate
        return create_reply(true, false)
      end
      
      super
    end
    
    def start_fixity_check
      success = Oubliette::SingleFixityJob.new(resource: @resource).queue_job
      
      respond_to do |format|
        format.html { 
          if success
            redirect_to @resource, notice: "Fixity job started" 
          else
            flash[:error] = "Error starting fixity job."            
            redirect_to @resource
          end
        }
        format.json { render json: {status: success} }
      end      
    end
    
    def start_characterisation
      success = Oubliette::CharacterisationJob.new(resource: @resource).queue_job
      respond_to do |format|
        format.html { 
          if success
            redirect_to @resource, notice: "Characterisation job started" 
          else
            flash[:error] = "Error starting characterisation job."            
            redirect_to @resource
          end
        }
        format.json { render json: {status: success} }
      end      
    end

    protected

    def authenticate_start_fixity_check!
      authenticate_user!
    end
    
    def authenticate_start_characterisation!
      authenticate_user!
    end
    
    
    def create_reply(success, characterise=true)
      Oubliette::CharacterisationJob.new(resource: @resource).queue_job if characterise
      super(success)
    end
    
    def set_parent
      if params[:file_batch_id].present?
        @parent = Oubliette::FileBatch.find(params[:file_batch_id])
      end
    end

    def new_resource(params={})
      PreservedFile.new( { status: PreservedFile::STATUS_NOT_CHECKED, ingestion_date: DateTime.now }.merge(params) )
    end

    def resource_params
      content_path = params.try(:[],'preserved_file').try(:delete,'content_path')
      if content_path
        content_file = resolve_content_path(content_path)
      else
        content_file = params.try(:[],'preserved_file').try(:delete,'content')
      end
      content_type = params.try(:[],'preserved_file').try(:delete,'content_type')
      original_filename = params.try(:[],'preserved_file').try(:[],'original_filename')
      ingestion_checksum = params.try(:[],'preserved_file').try(:delete,'ingestion_checksum')

      raise 'Cannot update file contents' if @resource && !@resource.new_record? && content_file

      super.tap do |params|
        if params.try(:[],'ingestion_log').try(:is_a?,String)
          content = params['ingestion_log']
          params['ingestion_log'] = ActiveFedora::File.new
          params['ingestion_log'].content = content
        end
        if content_file
          params['content'] = ActiveFedora::File.new
          params['content'].content = content_file
          params['content'].mime_type = content_type || content_file.try(:content_type) || 'application/octet-stream'
          params['content'].original_name = original_filename || content_file.try(:original_filename) || 'unnamed_file'
        end
        params['ingestion_checksum'] = ingestion_checksum.to_s if ingestion_checksum
      end
    end
    
    protected
    
      def resolve_content_path(path)
        ingestion_paths = Array(Oubliette.config['ingestion_path'])
        raise 'Ingestion from disk not supported' unless ingestion_paths.any?
        ingestion_paths.each do |ingestion_path|
          ingestion_path += File::SEPARATOR unless ingestion_path.ends_with? File::SEPARATOR
          abs_path = File.absolute_path(path)
          next unless abs_path.start_with?(ingestion_path) && abs_path.length > ingestion_path.length
          raise "Ingestion file #{abs_path} doesn't exist" unless File.exists?(abs_path)
          raise "Ingestion file #{abs_path} is a directory" if File.directory?(abs_path)
          return File.open(abs_path,'rb')
        end
        
        raise "Not allowed to ingest from #{path}"
      end
      
      def set_fixity_check_resource
        set_resource
      end
      def set_characterisation_resource
        set_resource
      end
      
      def set_resource(resource = nil)
        # Overridden to avoid loading resource from Solr, which would cause problems with 
        # contained log files.
        if resource
          @resource = resource
        else
          @resource = self.class.model_class.find(params[:id])
        end
        self.instance_variable_set(:"@#{self.class.model_name.element}",@resource)
      end      
    
  end
end
