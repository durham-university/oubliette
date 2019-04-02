module Oubliette
  class CreateBatchJob
    include Jobduct::ChannelJob
    include DurhamRails::Channels::ChannelBase

    request_reader :title, :note, :job_tag, :access_groups
    result_accessor :batch

    def run
      b = nil
      if job_tag.present?
        b = Oubliette::FileBatch.find_job_duplicate("#{job_tag}/batch")
        log!("Found duplicate batch with job_tag #{job_tag}/batch") if batch.present?
      end
      
      unless b.present?
        log!("Creating batch")
        unless user.present?
          log!(:error, "User not set, cannot create a new file batch")
          return
        end
        b = Oubliette::FileBatch.new(
          title: title, 
          note: note, 
          ingestion_date: DateTime.now, 
          job_tag: job_tag,
          access_groups: Array.wrap(access_groups || user.try(:default_access_group))
          )
        b.current_user = user
        unless b.valid?
          log!(:error,"Invalid batch attributes. #{b.errors.full_messages.join("\n")}")
          return
        end
        b.save
        log!("Created (#{b.id})")
      end
      self.batch = b.as_json
    end

  end
end