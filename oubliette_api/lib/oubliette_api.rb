require 'active_support'
require 'httmultiparty'
require 'durham_rails'

module Oubliette
  module API
    extend ActiveSupport::Autoload

    autoload :PreservedFile
    autoload :FileBatch
    autoload :FetchError
    autoload :IngestError
    autoload :ExportError

    autoload_under 'concerns' do
      autoload :ModelBase
    end

    def self.config
      @config ||= begin
        config = {}
        if defined?(Rails) && Rails.root
          path = Rails.root.join('config',"oubliette_api.yml")
          if File.exists? path
            config = YAML.load(ERB.new(File.read(path)).tap do |erb| erb.filename = path.to_s end .result)[Rails.env] || {}
          end
        end
        config
      end
    end
  end
end
