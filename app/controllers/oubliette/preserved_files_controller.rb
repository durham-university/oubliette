module Oubliette
  class PreservedFilesController < Oubliette::ApplicationController
    include Oubliette::ModelControllerBase

    def self.presenter_terms
      [:title, :note, :status, :check_date, :ingestion_date, :ingestion_log, :preservation_log, :ingestion_checksum, :content]
    end

    def self.form_terms
      [:title, :note, :content, :ingestion_log]
    end

    protected

    def new_resource(params={})
      PreservedFile.new( { status: PreservedFile::STATUS_NOT_CHECKED, ingestion_date: DateTime.now }.merge(params) )
    end

    def resource_params
      content_file = params.try(:[],'preserved_file').try(:delete,'content')

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
          params['content'].original_name = content_file.original_filename
          params['content'].mime_type = content_file.content_type
        end
      end
    end

  end
end
