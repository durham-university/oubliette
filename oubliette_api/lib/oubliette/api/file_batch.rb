module Oubliette
  module API
    class FileBatch
      include ModelBase

      attr_accessor :ingestion_date
      attr_accessor :note
      attr_accessor :job_tag

      def initialize
        super
      end

      def from_json(json)
        super(json)        
        @ingestion_date = DateTime.parse(json['ingestion_date'].to_s) if date_time_present?(json['ingestion_date'])
        @note = json['note']
        @files = json['files'].map do |m_json| Oubliette::API::PreservedFile.from_json(m_json) end if json.key?('files')
        @job_tag = json['job_tag']
      end

      def as_json(*args)
        json = super(*args)
        json['ingestion_date'] = @ingestion_date.to_s
        json['note'] = @note
        json['files'] = @files.map(&:as_json) if @files
        json['job_tag'] = @job_tag
        json
      end

      def record_url
        self.class.record_url(id)
      end
      
      def self.record_url(id)
        "#{self.base_uri}/#{self.model_name}/#{CGI.escape id}"
      end

      # NOTE: that this can return both FileBatches and top-level PreservedFiles
      def self.all
        return all_local if local_mode?
        response = self.get('/file_batches.json')
        raise FetchError, "Error fetching file_batches: #{response.code} - #{response.message}" unless response.code == 200
        # TODO: Handle paging properly
        json = JSON.parse(response.body)["resources"]
        json.map do |json|
          if json['type'] == 'batch'
            self.from_json(json)
          else
            Oubliette::API::PreservedFile.from_json(json)
          end
        end
      end

      def self.all_local
        local_class.all_top.to_a.map do |obj|
          json = obj.as_json
          if json['type'] == 'batch'
            self.from_json(json)
          else
            Oubliette::API::PreservedFile.from_json(json)
          end
        end
      end
      
      def self.create(params)
        return self.create_local(params) if local_mode?
        response = self.post("/file_batches.json", {body: {file_batch: params.slice(:title, :note, :job_tag) }} )
        return nil unless response.code == 200
        json = JSON.parse(response.body)
        return nil unless json['resource']
        Oubliette::API::FileBatch.from_json(json['resource'])
      end
      
      def self.create_local(params)
        local_batch = local_class.create(params.slice(:title, :note, :job_tag).merge(ingestion_date: DateTime.now))
        Oubliette::API::FileBatch.from_json(local_batch.as_json)
      end

      def self.model_name
        'file_batches'
      end
      
      def files
        fetch unless @files
        @files
      end
      
      def full
        fetch unless @files
      end            
      
      private
      
        def date_time_present?(dt)
          # .present? doesn't work in vanilla Ruby
          dt.is_a?(DateTime) ? true : ( (dt.nil? || dt=='') ? false : true )
        end
        
    end
  end
end
