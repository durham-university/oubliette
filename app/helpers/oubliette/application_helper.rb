module Oubliette
  module ApplicationHelper
    include DurhamRails::Helpers::BaseHelper

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
      return Oubliette::PreservedFile.model_name if controller.is_a?(Oubliette::StaticPagesController)
      return super
    end

    def model_class
      return Oubliette::PreservedFile if controller.is_a?(Oubliette::StaticPagesController)
      return super
    end
  end
end
