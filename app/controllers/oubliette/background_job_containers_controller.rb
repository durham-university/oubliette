module Oubliette
  class BackgroundJobContainersController < Oubliette::ApplicationController
    include DurhamRails::BackgroundJobContainersControllerBehaviour
    
    before_action :authenticate_fixity_job_user!, only: [:start_fixity_job]
    before_action :authenticate_export_job_user!, only: [:start_export_job]
    
    def self.form_terms
      super - [:job_category]
    end
    
    def start_fixity_job
      file_limit = params[:file_limit].try(:to_i) || 500
      time_limit = params[:time_limit].try(:to_i) || 30
      max_fail_count = params[:max_fail_count].try(:to_i) || 10
      success = Oubliette::FixityJob.new(file_limit: file_limit, time_limit: time_limit, max_fail_count: max_fail_count).queue_job
      
      respond_to do |format|
        format.html { redirect_to DurhamRails::BackgroundJobContainer, notice: "Fixity job started" }
        format.json { render json: {status: success } }
      end
    end
    
    def start_export_job
      job_params = export_job_params
      
      authorize_export_job_files(job_params[:export_file_ids])      
      
      job = Oubliette::ExportJob.new(job_params)
      success = job.queue_job
      respond_to do |format|
        format.html { redirect_to DurhamRails::BackgroundJobContainer, notice: "Export job started" }
        format.json { render json: {status: success, job_id: job.id } }
      end
    end
    
    protected
    
      def authorize_export_job_files(export_ids)
        files = Oubliette::PreservedFile.all.from_solr!.find_some(export_ids)
        nil_ind = files.index(nil)
        raise "File not found #{export_ids[nil_ind]}" unless nil_ind.nil?
        
        files.each do |file|
          authorize! :export, file
        end
      end
      
      def export_job_params
        export_ids_raw = Array.wrap(params[:export_ids])
        export_ids = []
        export_ids_raw.each do |raw_id|
          next unless raw_id.present?
          raw_id.split(/[\s,]+/).each do |id|
            export_ids << id
          end
        end
        raise 'No export_ids given' unless export_ids.present?
        raise 'Too many export ids given' if export_ids.length > 500

        export_method = params.fetch(:export_method, :store).to_sym
        raise "Invalid export method #{export_method}" unless [:store].include?(export_method)
        # Don't accept export destination when method == :store. Export destination
        # is the path where the file is written. Accepting it from params would require
        # sanitising it properly.
        export_destination = (export_method == :store ? nil : params[:export_destination])
        
        {
          export_file_ids: export_ids,
          export_method: export_method,
          export_note: params[:export_note],
          export_destination: export_destination
        }
      end
    
      def authenticate_fixity_job_user!
        authenticate_user!
      end
      
      def authenticate_export_job_user!
        authenticate_user!
      end
    
      def job_container_category
        :oubliette
      end
    
  end
end