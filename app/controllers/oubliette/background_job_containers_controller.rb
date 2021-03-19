module Oubliette
  class BackgroundJobContainersController < Oubliette::ApplicationController
    include DurhamRails::BackgroundJobContainersControllerBehaviour
    
    helper Jobduct::JobductHelper
    
    def self.form_terms
      super - [:job_category]
    end

    protected
    
      def job_container_category
        :oubliette
      end
    
  end
end