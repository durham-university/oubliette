module Oubliette
  class GenericPresenter
    include Hydra::Presenter
    include PresenterRenderer

    class <<self
      attr_accessor :presenter_class_cache
    end
    self.presenter_class_cache = {}

    def self.presenter_class_for(model_class, terms)
      self.presenter_class_cache[ [model_class,terms] ] ||= Class.new(GenericPresenter) do
        self.model_class = model_class
        self.terms = terms
      end
    end

  end
end
