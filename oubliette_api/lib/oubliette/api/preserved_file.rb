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
        @ingestion_date = DateTime.parse(json['ingestion_date'].to_s) if json['ingestion_date']
        @status = json['status']
        @check_date = DateTime.parse(json['check_date'].to_s) if json['check_date']
        @note = json['note']
        @ingestion_checksum = json['ingestion_checksum']
      end

      def as_json(*args)
        json = super(*args)
        json[:ingestion_date] = @ingestion_date.to_s
        json[:status] = @status
        json[:check_date] = @check_date.to_s
        json[:note] = @note
        json[:ingestion_checksum] = @ingestion_checksum
        json
      end

      def download_url
        "#{self.class.base_uri}/#{self.model_name}/#{CGI.escape id}/download"
      end

      def self.all
        return all_local if local_mode
        response = self.get('/preserved_files.json')
        raise FetchError, "Error fetching preserved_files: #{response.code} - #{response.message}" unless response.code == 200
        json = JSON.parse(response.body)
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

      def self.ingest(file,options={})
        unless file.respond_to?(:read)
          file=StringIO.new(file.to_s)
        end

        options[:original_filename] ||= 'unnamed_file' unless file.respond_to?(:original_filename)

        if options[:original_filename]
          file.instance_variable_set(:@original_filename, options[:original_filename])
          class << file
            def original_filename
              @original_filename
            end
          end
        end

        if local_mode
          begin
            f = local_class.ingest_file(file,options.slice(:title, :ingestion_log, :ingestion_checksum, :note, :content_type))
            f.save!
          rescue StandardError => e
            raise Oubliette::API::IngestError, "Unable to local ingest file: #{e.message}", e.backtrace
          end
          return from_json(f.as_json)
        end

        query_options = options.slice(:title, :ingestion_log, :ingestion_checksum, :note, :content_type).each_with_object({}) do |(k,v),o|
          o[:"preserved_file[#{k}]"] = v
        end

        resp = self.post('/preserved_files.json', query: {
            :'preserved_file[content]' => file
          }.merge(query_options) )

        begin
          json = JSON.parse(resp.body)
        rescue StandardError => e
          raise Oubliette::API::IngestError, "Unable to ingest file: #{e.message}", e.backtrace
        end
        raise Oubliette::API::IngestError, "Unable to ingest file. #{json['status']}" unless json['status']=='created'

        from_json(json['resource'])
      end

    end
  end
end
