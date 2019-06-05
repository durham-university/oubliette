module Oubliette
  class BatchIngestionJob
    include Jobduct::ChannelJob
    include DurhamRails::Channels::ChannelBase
    include DurhamRails::Channels::WithResource

    request_reader :files, :batch_title, :batch_note, :file_tag, :job_tag, :access_groups
    request_reader :notifications
    variable_accessor :ingested_files, :batch, :post_notify_sent
    result_accessor :files, as: :oubliette_files
    result_accessor :batch, as: :oubliette_batch

    def self.new_channel(params)
      params[:resource] = create_batch(params) unless params[:resource] || params[:resource_id]
      super(params)
    end  

    def run
      self.ingested_files = self.files.map do |file|
        file.merge(status: 'pending')
      end
      files_updated
    end

    def retry
      files_updated
    end

    def callback(callback)
      if callback
        if callback.callback_params[:original_file]
          ingested_file = self.ingested_files.find do |f|
            f[:file] == callback.callback_params[:original_file]
          end
          if ingested_file
            ingested_file[:callback_code] = callback.success_code
            if callback.success_code != Jobduct::Callback::CODE_ERROR
              ingested_file[:status] = 'finished'
              ingested_file[:oubliette_id] = callback.result[:preserved_file][:id]
              log!("Ingested file #{ingested_file[:file]} to Oubliette (#{ingested_file[:oubliette_id]})")
            else
              ingested_file[:status] = 'error'
              log!(:error, "Error ingesting file #{ingested_file[:file]} to Oubliette")
            end
          else
            log!(:error, "Couldn't find file for callback #{callback.callback_params[:orignal_file]}")
          end
        end
      end

      files_updated
    end

    def notify(action=nil)
      if action.try(:payload).try(:[],:notification) == 'post_ingest'
        ingested_file = self.ingested_files.find do |f|
          f[:file] == action.callback_params[:original_file]
        end
        if ingested_file
          log!(:debug,"File #{ingested_file[:file]} at post-ingest")
          ingested_file[:status] = 'post_ingest'
          ingested_file[:oubliette_id] = action.result[:preserved_file][:id]
          files_updated
        else
          log!(:error, "Couldn't find file for notification #{action.callback_params[:original_file]}")
        end
      end
    end

    private 

    def files_updated
      if self.ingested_files.any? do |file| file[:status] == 'pending' end
        ingest_next_file unless self.ingested_files.any? do |file| file[:status] == 'sent' end
      elsif self.ingested_files.all? do |file| file[:status] == 'finished' || file[:status] == 'post_ingest' end
        self.oubliette_files = ingested_files.map do |f| {file: f[:file], oubliette_id: f[:oubliette_id]} end
        self.oubliette_batch = batch_id
        if self.ingested_files.all? do |file| file[:status] == 'finished' end
          self.success_code = Jobduct::Channel.severest_code( ingested_files.map do |f| 
            f[:callback_code] || (f[:status] == 'finished' ? Jobduct::Channel::CODE_SUCCESS : Jobduct::Channel::CODE_ERROR)
          end )
          self.log!("Job done")
        elsif !self.post_notify_sent && notify?('post_ingest')
          send_notification(notification: 'post_ingest')
          self.post_notify_sent = true
        end
      end
    end

    def batch
      self.resource
    end

    def batch_id
      self.resource_id
    end
    
    def self.create_batch(params)
      if params[:job_tag].present?
        duplicate = Oubliette::FileBatch.find_job_duplicate("#{params[:job_tag]}/batch")
        return duplicate if duplicate.present?
      end

      user = User.find_by_user_key(params[:user])
      raise "User not set" unless user.present?

      batch = Oubliette::FileBatch.new(
        title: params[:batch_title] || 'unnamed batch', 
        job_tag: "#{params[:job_tag]}/batch",
        note: params[:batch_note], 
        ingestion_date: DateTime.now,
        access_groups: Array.wrap(params[:access_groups] || user.try(:default_access_group))
      )
      batch.current_user = user
      unless batch.valid?
        raise "Invalid batch attributes. #{batch.errors.full_messages.join("\n")}"
      end
      batch.save
      batch
    end

    def ingest_next_file
      file = ingested_files.find do |file| file[:status] == 'pending' end
      file[:status] = 'sent'
      file_title = file[:title] || "#{ingested_files.length}"

      file_job_tag = if job_tag.present?
        "#{job_tag}/file/#{file[:file]}"
      else
        nil
      end

      local_call("Ingest #{file_title}", {
        binding_key: ingest_binding,
        callback_params: {original_file: file[:file]},
        title: file_title,
        source_record: file[:source_record],
        description: file[:description],
        content_type: file[:content_type],
        content_path: file[:path] || file[:file],
        original_filename: file[:original_filename],
        ingestion_checksum: "md5:#{file[:md5]}",
        ingestion_log: '',
        note: file[:note],
        tag: file[:tag] || file_tag,
        access_groups: access_groups,
        job_tag: file_job_tag,
        parent_id: batch_id,
        notifications: 'post_ingest'
      })
    end

    def ingest_binding
      "ingest_file"
    end
    
    def notify?(event)
      notifications == true || Array.wrap(notifications).include?(event)
    end
    
  end
end