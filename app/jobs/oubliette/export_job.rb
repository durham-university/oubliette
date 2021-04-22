module Oubliette
  class ExportJob
    include Jobduct::ChannelJob
    include DurhamRails::Channels::ChannelBase
    include DurhamRails::Channels::WithJobContainer

    request_reader :export_method, default: :store, &:to_sym
    request_reader :export_batch_id
    request_reader :export_file_ids do |val| Array.wrap(val) end
    request_reader :export_destination, :export_note
    
    def self.new_channel(params)
      parse_ids(params)
      super(params)
    end

    def self.parse_ids(params)
      export_ids_raw = Array.wrap(params[:export_file_ids])
      export_ids = []
      export_ids_raw.each do |raw_id|
        next unless raw_id.present?
        raw_id.split(/[\s,]+/).each do |id|
          export_ids << id
        end
      end    
      params[:export_file_ids] = export_ids
    end

    def self.default_job_container_category
      :oubliette
    end
    
    def run
      log!("Starting export job")
      
      begin
        file_ids = export_file_ids
        if file_ids.empty? && export_batch_id.present?
          batch = Oubliette::FileBatch.find(export_batch_id)
          batch.ordered_members.from_solr!
          file_ids = batch.files.map(&:id)
        end
        
        actor = Oubliette::ExportActor.new(nil,{
          export_file_ids: file_ids,
          export_method: export_method,
          export_destination: export_destination,
          export_note: export_note,
          progress_proc: Proc.new do @channel.save end
        })
        actor.instance_variable_set(:@log, log)
        
        actor.export!
      rescue StandardError => e
        log!(e)
      end
    
      log!("Finished export job")
    end
  
  end
end