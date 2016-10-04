module Oubliette
  module API
    class PreservedFile
      include ModelBase

      attr_accessor :ingestion_date
      attr_accessor :status
      attr_accessor :check_date
      attr_accessor :note
      attr_accessor :ingestion_checksum

      def initialize
        super
      end

      def from_json(json)
        super(json)        
        @ingestion_date = DateTime.parse(json['ingestion_date'].to_s) if date_time_present?(json['ingestion_date'])
        @status = json['status']
        @check_date = DateTime.parse(json['check_date'].to_s) if date_time_present?(json['check_date'])
        @note = json['note']
        @ingestion_checksum = json['ingestion_checksum']
      end

      def as_json(*args)
        json = super(*args)
        json['ingestion_date'] = @ingestion_date.to_s
        json['status'] = @status
        json['check_date'] = @check_date.to_s
        json['note'] = @note
        json['ingestion_checksum'] = @ingestion_checksum
        json
      end

      def download_url
        "#{self.class.base_uri}/#{self.model_name}/#{CGI.escape id}/download"
      end
      
      def record_url
        self.class.record_url(id)
      end
      
      def self.record_url(id)
        "#{self.base_uri}/#{self.model_name}/#{CGI.escape id}"
      end
      
      # yields a Net::HTTPResponse
      def download(&block)
        return download_local(&block) if local_mode?
        (username,password) = [self.class.authentication_config.try(:[],'username'), self.class.authentication_config.try(:[],'password')]
        ca_file = self.class.authentication_config.try(:[],'ca_file')
        uri = URI(download_url)
        req_options = { use_ssl: (uri.scheme=='https') }
        req_options[:verify_mode] = OpenSSL::SSL::VERIFY_NONE if [false,'false'].include?(Oubliette::API::config['verify_certificate'])
        Net::HTTP.start(uri.hostname, uri.port, req_options ) do |http|
          http.ca_file = ca_file if ca_file.present?
          req = Net::HTTP::Get.new(uri)
          req.basic_auth(username, password) if username.present?
          http.request(req, &block)
        end
      end

      def self.all
        return all_local if local_mode?
        response = self.get('/preserved_files.json')
        raise FetchError, "Error fetching preserved_files: #{response.code} - #{response.message}" unless response.code == 200
        # TODO: Handle paging properly
        json = JSON.parse(response.body)["resources"]
        json.map do |file_json|
          self.from_json(file_json)
        end
      end

      def self.all_local
        local_class.all.to_a.map do |repo|
          self.from_json(repo.as_json)
        end
      end

      def self.model_name
        'preserved_files'
      end

      # to ingest in a batch, give parent batch in options[:parent]
      def self.ingest(file,options={})
        unless file.respond_to?(:read)
          file=StringIO.new(file.to_s)
        end

        if local_mode?
          begin
            f = local_class.ingest_file(file,options.slice(:title, :ingestion_log, :ingestion_checksum, :note, :content_type, :original_filename))
            f.save!
            Oubliette::CharacterisationJob.new(resource: f).queue_job
            if options[:parent]
              parent_id = (options[:parent].is_a?(Oubliette::API::FileBatch) ? options[:parent].id : options[:parent].to_s)
              local_parent = Oubliette::FileBatch.find(parent_id)
              local_parent.ordered_members << f
              local_parent.save
            end
          rescue StandardError => e
            raise Oubliette::API::IngestError, "Unable to local ingest file: #{e.message}", e.backtrace
          end
          return from_json(f.as_json)
        end

        # HTTParty requires the file to respond to these methods
        unless file.respond_to?(:original_filename)
          file.instance_variable_set(:@original_filename, (options[:original_filename] || 'unnamed_file') )
          class << file
            def original_filename
              @original_filename
            end
          end
        end
        unless file.respond_to?(:content_type)
          file.instance_variable_set(:@content_type, (options[:content_type] || 'application/octet-stream') )
          class << file
            def content_type
              @content_type
            end
          end
        end

        query_options = options.slice(:title, :ingestion_log, :ingestion_checksum, :note, :content_type, :original_filename).each_with_object({}) do |(k,v),o|
          o[:"preserved_file[#{k}]"] = v
        end
        
        post_url = 'preserved_files.json'
        if options[:parent]
          if options[:parent].is_a?(Oubliette::API::FileBatch)
            post_url = "file_batches/#{CGI.escape(options[:parent].id)}/preserved_files.json"
          else
            post_url = "file_batches/#{CGI.escape(options[:parent].to_s)}/preserved_files.json"
          end
        end

        resp = self.post(post_url, query: {
            :'preserved_file[content]' => file
          }.merge(query_options) )

        begin
          json = JSON.parse(resp.body)
        rescue StandardError => e
          raise Oubliette::API::IngestError, "Unable to ingest file: #{e.message}", e.backtrace
        end
        raise Oubliette::API::IngestError, "Unable to ingest file. #{json['error']}" unless json['status']=='created'

        from_json(json['resource'])
      end
      
      private
      
        def download_local
          yield LocalDownload.new(local_class.find(id))
        end
      
        def date_time_present?(dt)
          # .present? doesn't work in vanilla Ruby
          dt.is_a?(DateTime) ? true : ( (dt.nil? || dt=='') ? false : true )
        end
        
        class LocalDownload
          def initialize(obj)
            @obj = obj
          end
          def read_body(&block)
            @obj.content.stream.each(&block)
          end
          def content_type
            @obj.content.mime_type
          end
        end

    end
  end
end
