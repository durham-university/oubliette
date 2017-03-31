module Oubliette
  class FileBatchesController < Oubliette::ApplicationController
    include DurhamRails::ModelControllerBase

    def self.presenter_terms
      [:title, :note, :ingestion_date]
    end

    def self.form_terms
      [:title, :note, :job_tag]
    end

    def self.resources_paging_sort
      'ingestion_date_dtsi desc'
    end
    
    def index
      @query = params['query']
      super
    end

    def create
      duplicate = Oubliette::FileBatch.find_job_duplicate(params.try(:[],'file_batch').try(:[],'job_tag'))
      if duplicate.present?
        @resource = duplicate
        return create_reply(true)
      end
      
      super
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
      self.class.index_resources(page, per_page, params['query'])
    end
    
    def self.index_resources(page=1, per_page=20, query=nil)
      resources = FileBatch.all_top
      if query.present?
        query = query.gsub(/[^[:alpha:]0-9\.'-]/,' ').strip
        query = query.split(/\s+/).select do |s| s.length >= 2 end
        query = query[0..9] if query.length > 10
        if query.any?
          solr_query = query.map do |t| "title_tesim:\"#{t}\"" end .join(' AND ')
          resources = resources.where(solr_query)
        end
      end
      resources = self.resources_for_page(page: page, per_page: per_page, from: resources)
      resources
    end
    

  end
end
