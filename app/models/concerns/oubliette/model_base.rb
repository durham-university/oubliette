module Oubliette
  module ModelBase
    extend ActiveSupport::Concern

    def to_s
      "#{title}"
    end

    def allow_destroy?
      # TODO: check date isn't too far in the past, at the moment ActiveFedora
      #       doesn't get create date for objects loaded from Solr
      return true
    end
    
    def as_json(*args)
      super(*args).except('head','tail')
    end
    
  end
end
