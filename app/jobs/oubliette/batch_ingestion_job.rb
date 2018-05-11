module Oubliette
  class BatchIngestionJob
    include Jobduct::ChannelJob
    include DurhamRails::Channels::ChannelBase
    include DurhamRails::Channels::WithResource

    request_reader :files, :batch_title, :batch_note, :file_tag, :job_tag, :access_groups
    variable_accessor :ingested_files, :batch
    result_accessor :files, as: :oubliette_files
    result_accessor :batch, as: :oubliette_batch

    def self.new_channel(params)
      params[:resource] = create_batch(params) unless params[:resource] || params[:resource_id]
      super(params)
    end  

    def run
      self.ingested_files = []
      callback(nil)      
    end

    def callback(callback)
      if callback
        if callback.callback_params[:original_file]
          ingested_file = self.ingested_files.find do |f|
            f[:file] == callback.callback_params[:original_file]
          end
          if ingested_file
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

      if self.ingested_files.last.nil?
        ingest_next_file
      elsif self.ingested_files.last[:status] == 'finished'
        if self.ingested_files.count == files.count
          if self.ingested_files.all? do |f| f[:status] == 'finished' end
            self.oubliette_files = ingested_files.map do |f| {file: f[:file], oubliette_id: f[:oubliette_id]} end
            self.oubliette_batch = batch_id
            self.log!("Job done")
          end
        else
          ingest_next_file
        end
      end
      
    end

    private 

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
      Oubliette::FileBatch.create(
        title: params[:batch_title] || 'unnamed batch', 
        job_tag: "#{params[:job_tag]}/batch",
        note: params[:batch_note], 
        access_groups: params[:access_groups],
        ingestion_date: DateTime.now
      )
    end

    def ingest_next_file
      file = files[self.ingested_files.count]
      self.ingested_files << { file: file[:file], status: 'sent' }
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
        content_path: file[:file],
        original_filename: file[:original_filename],
        ingestion_checksum: "md5:#{file[:md5]}",
        ingestion_log: '',
        note: file[:note],
        tag: file[:tag] || file_tag,
        access_groups: access_groups,
        job_tag: file_job_tag,
        parent_id: batch_id
      })
    end

    def ingest_binding
      "ingest_file"
    end
    
    
  end
end