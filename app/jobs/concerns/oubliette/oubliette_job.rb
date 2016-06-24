module Oubliette::OublietteJob
  extend ActiveSupport::Concern

  def queue
    Oubliette.queue
  end
end
