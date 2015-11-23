module Oubliette
  module PresenterRenderer
    extend ActiveSupport::Concern

    def present_terms(view_context, include_terms = :all, &block)
      Renderer.new(self,view_context).present_terms(include_terms, &block)
    end

    def field_partial_paths(field_name)
      ["#{model_path}/show_fields/_#{field_name}", "oubliette/records/show_fields/_#{field_name}",
       "#{model_path}/show_fields/_default", "oubliette/records/show_fields/_default"]
    end

    def model_path
      @model_path ||= ActiveSupport::Inflector.tableize(model_name)
    end

    def model_name
      self.model_class.model_name
    end

    class Renderer
      include ActionView::Helpers::TranslationHelper

      def initialize(presenter, view_context)
        @presenter = presenter
        @view_context = view_context
      end

      def present_terms(terms = :all, &block)
        terms = @presenter.terms if terms == :all
        self.fields(terms, &block)
      end

      def value(field_name, locals = {})
        render_show_field_partial(field_name, locals)
      end

      def label(field)
        t(:"#{model_name.param_key}.#{field}", scope: label_scope, default: field.to_s.humanize).presence
      end

      def fields(terms, &_block)
        @view_context.safe_join(terms.map { |term| yield self, term })
      end

      protected

        def render_show_field_partial(field_name, locals)
          partial = find_field_partial(field_name)
          @view_context.render( partial, locals.merge(key: field_name, record: @presenter) )
        end

        def find_field_partial(field_name)
          @presenter.field_partial_paths(field_name).find do |partial|
            Rails.logger.debug "Looking for show field partial #{partial}"
            return partial.sub(/\/_/, '/') if partial_exists?(partial)
          end
        end

        def partial_exists?(partial)
          @view_context.lookup_context.find_all(partial).any?
        end

        def label_scope
          :"simple_form.labels"
        end

        def model_name
          @presenter.model_name
        end

    end

  end
end
