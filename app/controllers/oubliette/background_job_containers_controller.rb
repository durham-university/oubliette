module Oubliette
  class BackgroundJobContainersController < Oubliette::ApplicationController
    include DurhamRails::BackgroundJobContainersControllerBehaviour
    
    before_action :authenticate_fixity_job_user!, only: [:start_fixity_job]
    
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
    
    
    protected
    
      def authenticate_fixity_job_user!
        authenticate_user!
      end
    
      def job_container_category
        :oubliette
      end
    
  end
end