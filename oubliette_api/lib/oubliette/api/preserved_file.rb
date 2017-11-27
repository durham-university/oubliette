module Oubliette
  module API
    class PreservedFile
      include ModelBase

      attr_accessor :ingestion_date
      attr_accessor :status
      attr_accessor :check_date
      attr_accessor :note
      attr_accessor :tag
      attr_accessor :ingestion_checksum
      attr_accessor :job_tag
      attr_accessor :parent_id

      def initialize
        super
      end

      def from_json(json)
        super(json)        
        @ingestion_date = DateTime.parse(json['ingestion_date'].to_s) if date_time_present?(json['ingestion_date'])
        @status = json['status']
        @check_date = DateTime.parse(json['check_date'].to_s) if date_time_present?(json['check_date'])
        @note = json['note']
        @tag = json['tag']
        @ingestion_checksum = json['ingestion_checksum']
        @job_tag = json['job_tag']
        @parent_id = json['parent_id']
      end

      def as_json(*args)
        json = super(*args)
        json['ingestion_date'] = @ingestion_date.to_s
        json['status'] = @status
        json['check_date'] = @check_date.to_s
        json['note'] = @note
        json['tag'] = Array.wrap(@tag)
        json['ingestion_checksum'] = @ingestion_checksum
        json['job_tag'] = @job_tag
        json['parent_id'] = @parent_id
        json
      end

      def parent
        if @parent_id
          @parent ||= Oubliette::API::FileBatch.find(@parent_id)
        else
          nil
        end
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
        req_options[:ca_file] = ca_file if ca_file.present?
        Net::HTTP.start(uri.hostname, uri.port, req_options ) do |http|
          req = Net::HTTP::Get.new(uri)
          req.basic_auth(username, password) if username.present?
          http.request(req, &block)
        end
      end

      def self.path_ingest?
        @path_ingest ||= Oubliette::API.config.fetch('path_ingest', false)
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
            f = local_class.ingest_file(file,options.slice(:title, :ingestion_log, :ingestion_checksum, :note, :tag, :content_type, :original_filename, :job_tag))
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

        query_options = options.slice(:title, :ingestion_log, :ingestion_checksum, :note, :tag, :content_type, :original_filename, :job_tag).each_with_object({}) do |(k,v),o|
          v = Array.wrap(v) if k == :tag
          o[:"preserved_file[#{k}]"] = v
        end

        if path_ingest?
          query_options.merge!({ :'preserved_file[content_path]' => file.path })
        else
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
          query_options.merge!({ :'preserved_file[content]' => file })
        end
        
        post_url = '/preserved_files.json'
        if options[:parent]
          if options[:parent].is_a?(Oubliette::API::FileBatch)
            post_url = "/file_batches/#{CGI.escape(options[:parent].id)}/preserved_files.json"
          else
            post_url = "/file_batches/#{CGI.escape(options[:parent].to_s)}/preserved_files.json"
          end
        end

        resp = self.post(post_url, query: query_options)

        begin
          json = JSON.parse(resp.body)
        rescue StandardError => e
          raise Oubliette::API::IngestError, "Unable to ingest file: #{e.message}", e.backtrace
        end
        raise Oubliette::API::IngestError, "Unable to ingest file. #{json['error']}" unless json['status']=='created'

        from_json(json['resource'])
      end
      
      # options should consist of 
      #    export_ids: []  (required)
      #    export_method: (optional, defaults to store)
      #    export_destination: (optional, not all methods will require this)
      #    export_note: (optional, free text note about export included in logs)
      def self.export(options)
        raise "Export not supported in local mode" if local_mode?
        
        post_url = "/background_job_containers/start_export_job.json"
        query_options = options.slice(:export_ids, :export_method, :export_destination, :export_note)
        resp = self.post(post_url, query: query_options)
        
        begin
          json = JSON.parse(resp.body)
        rescue StandardError => e
          raise Oubliette::API::ExportError, "Error starting export job: #{e.message}", e.backtrace
        end
        raise Oubliette::API::IngestError, "Unable to start export job. #{json['error']}" unless json['status']==true
        
        json['job_id']
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
