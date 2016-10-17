module Oubliette
  class PreservedFilesController < Oubliette::ApplicationController
    include DurhamRails::ModelControllerBase

    def self.presenter_terms
      [:title, :note, :status, :check_date, :ingestion_date, :ingestion_log, :preservation_log, :characterisation, :ingestion_checksum, :content]
    end

    def self.form_terms
      [:title, :note, :content, :ingestion_log]
    end

    def self.resources_paging_sort
      'ingestion_date_dtsi desc'
    end

    protected
    
    def create_reply(success)
      Oubliette::CharacterisationJob.new(resource: @resource).queue_job
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
        ingestion_path = Oubliette.config['ingestion_path']
        raise 'Ingestion from disk not supported' unless ingestion_path
        ingestion_path += File::SEPARATOR unless ingestion_path.ends_with? File::SEPARATOR
        unless File.absolute_path(path).start_with?(ingestion_path) && path.length > ingestion_path.length
          raise "Not allowed to ingest from #{path}"
        end
        path = File.absolute_path(path)
        raise "Ingestion file #{path} doesn't exist" unless File.exists?(path)
        raise "Ingestion file #{path} is a directory" if File.directory?(path)
        File.open(path,'rb')
      end
    
  end
end
