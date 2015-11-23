module Oubliette
  class GenericForm < GenericPresenter
    include HydraEditor::Form

    class <<self
      attr_accessor :form_class_cache
    end
    self.form_class_cache = {}


    def field_partial_paths(field_name)
      ["#{model_path}/edit_fields/_#{field_name}", "oubliette/records/edit_fields/_#{field_name}",
       "#{model_path}/edit_fields/_default", "oubliette/records/edit_fields/_default"]
    end

    def self.form_class_for(model_class, terms, required_fields=[])
      self.form_class_cache[ [model_class,terms, required_fields] ] ||= Class.new(GenericForm) do
        self.model_class = model_class
        self.terms = terms
        self.required_fields = required_fields
      end
    end
  end
end
