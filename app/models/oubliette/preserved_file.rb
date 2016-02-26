module Oubliette
  class PreservedFile < ActiveFedora::Base
    include ModelBase
    include DurhamRails::NoidBehaviour

    contains :content, class_name: 'ActiveFedora::File'
    contains :ingestion_log, class_name: 'ActiveFedora::File'
    contains :preservation_log, class_name: 'ActiveFedora::File'

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

    property :title, multiple: false, predicate: ::RDF::Vocab::DC.title
    property :note, multiple: false, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns/oubliette#admin_note')

    property :ingestion_checksum, multiple: false, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns/oubliette#ingestion_checksum')
    validate :validate_ingestion_checksum

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

      readable = content.content || ''
      readable = StringIO.new(readable) if readable.is_a? String
      readable.rewind

      buf = ""
      while readable.read(16384, buf)
        digest.update(buf)
      end
      readable.rewind

      digest.hexdigest
    end

    def validate_ingestion_checksum
      if ingestion_checksum.present?
        split = ingestion_checksum.split(':',2)
        split.unshift('md5') if split.length==1
        algorithm = split[0]
        received_checksum = split[1].strip
        checksum = content_checksum(algorithm)
        if checksum == nil
          errors[:checksum] ||= []
          errors[:checksum] << "Unsupported checksum algorithm #{split[0]}"
          return false
        elsif checksum != received_checksum
          errors[:content] ||= []
          errors[:content] << 'File contents don\'t match the checksum'
          return false
        end
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
  end
end
