module Oubliette
  class PreservedFile < ActiveFedora::Base
    include ModelBase

    contains :content, class_name: 'ActiveFedora::File'
    contains :ingestion_log, class_name: 'ActiveFedora::File'
    contains :preservation_log, class_name: 'ActiveFedora::File'

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

    def update(params)
      [:ingestion_log, :preservation_log].each do |key|
        if params.key?(key) && params[key].is_a?(String)
          contents = params[key]
          self.send(key).content = contents
          params = params.except(key)
        end
      end
      super(params)
    end
  end
end
