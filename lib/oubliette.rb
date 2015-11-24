require 'sass-rails'
require 'bootstrap-sass'
require 'bootstrap-sass-extras'
require 'jquery-rails'
require 'jquery-ui-rails'
#require 'dropzonejs-rails'
require 'simple_form'
require 'active-fedora'
require 'hydra-editor'
require "oubliette/engine"

module Oubliette
  def self.queue
    @queue ||= Oubliette::Resque::Queue.new('oubliette')
  end

  def self.config
    @config ||= begin
      config_file = Rails.root.join('config','oubliette.yml')
      File.exists?(config_file) ? YAML.load_file(config_file)[Rails.env] : {}
    end
  end
end
