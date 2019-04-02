module Oubliette
  class ChannelsController < Oubliette::ApplicationController
    include DurhamRails::ImpersonateBehaviour
    allow_impersonate [:show, :call, :tunnel_callback], user_key: :user
    
    include DurhamRails::ChannelsControllerBehaviour

    protected

    def link_channel_json(keys, v, view)
      if keys.last.ends_with?('oubliette_id')
        view.content_tag(:a, v, href: oubliette.preserved_file_url(v))
      elsif keys.last.ends_with?('batch')
        view.content_tag(:a, v, href: oubliette.file_batch_url(v))
      elsif keys[-2] == 'preserved_file' 
        if keys.last == 'id'
          view.content_tag(:a, v, href: oubliette.preserved_file_url(v))
        elsif keys.last == 'parent_id'
          view.content_tag(:a, v, href: oubliette.file_batch_url(v))
        end
      end
    end
    
  end
end