module Oubliette
  class FileBatchesController < Oubliette::ApplicationController
    include DurhamRails::ModelControllerBase

    def self.presenter_terms
      [:title, :note, :ingestion_date]
    end

    def self.form_terms
      [:title, :note]
    end

    def self.resources_paging_sort
      'ingestion_date_dtsi desc'
    end

    protected
    
    def set_parent
    end

    def new_resource(params={})
      FileBatch.new( { ingestion_date: DateTime.now }.merge(params) )
    end
    
    def index_resources
      per_page = [[params.fetch('per_page', 20).to_i, 100].min, 5].max
      page = [params.fetch('page', 1).to_i, 1].max
      self.class.index_resources(page, per_page)
    end
    
    def self.index_resources(page=1, per_page=20)
      resources = FileBatch.all_top
      resources = self.resources_for_page(page: page, per_page: per_page, from: resources)
      resources
    end
    

  end
end
