module Oubliette
  module ApplicationHelper
    def render_one(view_context,partials,*args)
      view_context.render(resolve_partial(view_context,partials),*args)
    end

    def render_overrideable(view_context, partial, *args)
      render_one(view_context, ["schmit/#{model_name.pluralize}/#{partial}", "schmit/shared/#{partial}"], *args)
    end

    def resolve_partial(view_context,partials)
      partials.find do |partial|
        partial = partial.split('/').tap do |s| s.last.insert(0,'_') end .join('/')
        view_context.lookup_context.find_all(partial).any?
      end
    end

    def download_link(item,file_ref: :original_file, title: nil)
      title ||= file_ref.to_s.humanize

      file = item.generic_files.to_a.find do |file| file.is_a? EADFile end
      return '' if !file
      return '' if !file.send(file_ref)

      return '' unless can? :show, file
      return '' unless can? :download, file.try(file_ref)

      link_to(title,download_path(file,file: file_ref))
    end

    def model_name
      if controller.is_a? ActionView::TestCase::TestController
        self.instance_variable_get(:@request).instance_variable_get(:@env)["action_dispatch.request.path_parameters"][:controller].split('/').last.singularize
      else
        controller.class.model_name
      end
    end

    def model_class
      if controller.is_a? ActionView::TestCase::TestController
        "Oubliette::#{self.instance_variable_get(:@request).instance_variable_get(:@env)["action_dispatch.request.path_parameters"][:controller].split('/').last.singularize.camelize}".constantize
      else
        controller.class.model_class
      end
    end

    def format_time(time)
      time = DateTime.parse(time) if time.is_a? String
      time.strftime('%F %R')
    end
  end
end
