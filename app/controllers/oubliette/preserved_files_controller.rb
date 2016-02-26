module Oubliette
  class PreservedFilesController < Oubliette::ApplicationController
    include DurhamRails::ModelControllerBase

    def self.presenter_terms
      [:title, :note, :status, :check_date, :ingestion_date, :ingestion_log, :preservation_log, :ingestion_checksum, :content]
    end

    def self.form_terms
      [:title, :note, :content, :ingestion_log]
    end

    protected
    
    def set_parent
    end

    def new_resource(params={})
      PreservedFile.new( { status: PreservedFile::STATUS_NOT_CHECKED, ingestion_date: DateTime.now }.merge(params) )
    end

    def resource_params
      content_file = params.try(:[],'preserved_file').try(:delete,'content')
      content_type = params.try(:[],'preserved_file').try(:delete,'content_type')

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
          params['content'].mime_type = content_type || content_file.content_type || 'application/octet-stream'
          params['content'].original_name = content_file.original_filename || 'unnamed_file'
        end
      end
    end

  end
end
