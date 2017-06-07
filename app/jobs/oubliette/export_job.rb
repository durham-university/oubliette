module Oubliette
  class ExportJob
    include DurhamRails::Jobs::JobBase
    include Oubliette::OublietteJob
    include DurhamRails::Jobs::WithJobContainer

    attr_accessor :export_file_ids, :export_method, :export_destination, :export_note
    
    def initialize(params={})
      self.export_file_ids = Array.wrap(params.fetch(:export_file_ids))
      self.export_method = params.fetch(:export_method, :store)
      self.export_destination = params[:export_destination]
      self.export_note = params[:export_note]
      super(params)
    end
    
    def dump_attributes
      super + [:export_file_ids, :export_method, :export_destination, :export_note]
    end
    
    def default_job_container_category
      :oubliette
    end
    
    def run_job
      log!("Starting export job")
      
      actor = Oubliette::ExportActor.new(nil,{
        export_file_ids: export_file_ids,
        export_method: export_method,
        export_destination: export_destination,
        export_note: export_note
      })
      actor.instance_variable_set(:@log, log)
      
      begin
        actor.export!
      rescue StandardError => e
        log!(e)
      end

      log!("Finished export job")
    end

  end
end