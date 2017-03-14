module Oubliette
  class PreservedFile < ActiveFedora::Base
    include ModelBase
    #include Hydra::Works::WorkBehavior
    include DurhamRails::FastContainerItem
    fast_container_item_pcdm_compatibility
    
    include DurhamRails::WithBackgroundJobs
    include DurhamRails::NoidBehaviour

    has_subresource :content, class_name: 'ActiveFedora::File'
    has_subresource :ingestion_log, class_name: 'ActiveFedora::File'
    has_subresource :preservation_log, class_name: 'ActiveFedora::File'
    has_subresource :characterisation, class_name: 'ActiveFedora::File'

    # ActiveFedora::File also has original_name and mime_type.
    # These are really only relevant to the main content.

    property :ingestion_date, multiple: false, predicate: ::RDF::Vocab::DC.dateSubmitted, class_name: 'DateTime' do |index|
      index.type :date
      index.as :stored_sortable
    end

    STATUS_NOT_CHECKED = 'not checked'
    STATUS_PASS = 'passing'
    STATUS_ERROR = 'error'

    property :status, multiple:false, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns/oubliette#preservation_status')
    validates_inclusion_of :status, in: [STATUS_NOT_CHECKED, STATUS_PASS, STATUS_ERROR], allow_nil: false

    property :check_date, multiple: false, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns/oubliette#last_checked'), class_name: 'DateTime' do |index|
      index.type :date
      index.as :stored_sortable
    end

    property :title, multiple: false, predicate: ::RDF::Vocab::DC.title do |index|
      index.as :stored_searchable
    end
    property :note, multiple: false, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns/oubliette#admin_note')

    property :ingestion_checksum, multiple: false, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns/oubliette#ingestion_checksum')

    # Override log setters to accept strings in addition to files
    [:ingestion_log, :preservation_log].each do |key|
      self.class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{key}=(*args)
          value = args.first
          if value.is_a? String
            self.send(:#{key}).content = value
          else
            super
          end
        end
      CODE
    end
    
    def parent(reload=false)
      @parent = nil if reload
      @parent ||= ordered_by.to_a.find do |m| m.is_a? FileBatch end
    end
    
    def content_io
      # TODO: change this to a streaming IO
      readable = content.content || ''
      readable = StringIO.new(readable) if readable.is_a? String
      readable.rewind      
      readable
    end

    def content_checksum(algorithm='md5')
      digest = nil
      case algorithm.downcase
      when 'md5'
        digest = Digest::MD5.new
      when 'sha256', 'sha-256', 'sha'
        digest = Digest::SHA256.new
      when 'sha384', 'sha-384'
        digest = Digest::SHA384.new
      when 'sha512', 'sha-512'
        digest = Digest::SHA512.new
      else
        return nil
      end

      readable = content_io
      
      buf = ""
      while readable.read(16384, buf)
        digest.update(buf)
      end
      readable.rewind

      digest.hexdigest
    end

    def check_ingestion_fixity
      if ingestion_checksum.present?
        split = ingestion_checksum.split(':',2)
        split.unshift('md5') if split.length==1
        algorithm = split[0]
        received_checksum = split[1].strip
        checksum = content_checksum(algorithm)
        return false if checksum == nil || checksum != received_checksum
      end
      true
    end

    def self.ingest_file(file,params={})
      f = PreservedFile.new(params.except(:content_type, :original_filename).merge({status: PreservedFile::STATUS_NOT_CHECKED, ingestion_date: DateTime.now}))
      f.content.content = file
      f.content.mime_type = params[:content_type] || file.try(:content_type) || 'application/octet-stream'
      f.content.original_name = params[:original_filename] || file.try(:original_filename) ||
          (file.try(:path) ? File.basename(file.path) : nil) || 'unnamed_file'
      f
    end
    
    def as_json(*args)
      super(*args).tap do |json|
        parent_id = parent.try(:id)
        json.merge!({'parent_id' => parent_id}) if parent_id.present?
      end
    end    
    
  end
end
