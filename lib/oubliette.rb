require 'sass-rails'
require 'bootstrap-sass'
require 'bootstrap-sass-extras'
require 'jquery-rails'
#require 'jquery-ui-rails'
#require 'dropzonejs-rails'
require 'simple_form'
require 'active-fedora'
require 'active_fedora/noid'
require 'durham_rails'
require "oubliette/engine"

module Oubliette
  def self.queue
    @queue ||= Oubliette::Resque::Queue.new('oubliette')
  end

  def self.config
    @config ||= begin
      path = Rails.root.join('config','oubliette.yml')
      if File.exists?(path)
        YAML.load(ERB.new(File.read(path)).tap do |erb| erb.filename = path.to_s end .result)[Rails.env]
      else
        {}
      end
    end
  end
end
