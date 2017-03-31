module Oubliette
  class FileBatch < ActiveFedora::Base
    include ModelBase
    include DurhamRails::JobTag
    #include Hydra::Works::CollectionBehavior
    include DurhamRails::FastContainer
    fast_container_pcdm_compatibility
    
    include DurhamRails::NoidBehaviour
    
    property :title, multiple: false, predicate: ::RDF::Vocab::DC.title do |index|
      index.as :stored_searchable
    end
    property :note, multiple: false, predicate: ::RDF::URI.new('http://collections.durham.ac.uk/ns/oubliette#admin_note')

    property :ingestion_date, multiple: false, predicate: ::RDF::Vocab::DC.dateSubmitted, class_name: 'DateTime' do |index|
      index.type :date
      index.as :stored_sortable
    end

    def files
      ordered_members.to_a.select do |m| m.is_a? PreservedFile end
    end    
    
    def allow_destroy?
      return ordered_member_ids.empty?
    end
    
    def as_json(*args)
      super(*args).tap do |json|
        json.merge!({
          'files' => files.map(&:as_json)
        }) if args.first.try(:fetch,:include_children,false)
        json['type'] = 'batch'
      end
    end    
    
    def ordered_object_ids
      # Optimise getting object_ids. PCDM default implementation does some
      # unnecessary work. Note that this doesn't filter pcdm objects from other
      # possible members. However, there really shouldn't be any other members.
      ordered_members.association.target.target_ids
    end
    
    def ordered_collection_ids
      # There should be no sub-collections, and default implementation can be slow.
      []
    end
    
    def self.all_top
#      ActiveFedora::Base.where('has_model_ssim:"Oubliette::FileBatch" OR (has_model_ssim:"Oubliette::PreservedFile" AND -_query_:"{!join from=ordered_targets_ssim to=id}proxy_in_ssi:*")')
      ActiveFedora::Base.where('has_model_ssim:"Oubliette::FileBatch" OR (has_model_ssim:"Oubliette::PreservedFile" AND -_query_:"{!join from=ordered_item_ids_sim to=id}has_model_ssim:\"Oubliette::FileBatch\"")')
    end

  end
end