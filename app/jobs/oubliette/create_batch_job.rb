module Oubliette
  class CreateBatchJob
    include Jobduct::ChannelJob
    include DurhamRails::Channels::ChannelBase

    request_reader :title, :note, :job_tag
    result_accessor :batch

    def run
      b = nil
      if job_tag.present?
        b = Oubliette::FileBatch.find_job_duplicate("#{job_tag}/batch")
        log!("Found duplicate batch with job_tag #{job_tag}/batch") if batch.present?
      end
      
      unless b.present?
        log!("Creating batch")
        b = Oubliette::FileBatch.create(title: title, note: note, ingestion_date: DateTime.now, job_tag: job_tag)
        log!("Created (#{b.id})")
      end
      self.batch = b.as_json
    end

  end
end