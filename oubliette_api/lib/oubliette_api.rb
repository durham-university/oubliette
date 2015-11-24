require 'active_support'
require 'httmultiparty'

module Oubliette
  module API
    extend ActiveSupport::Autoload

    autoload :PreservedFile
    autoload :FetchError
    autoload :IngestError

    autoload_under 'concerns' do
      autoload :ModelBase
    end

    def self.config
      @config ||= begin
        config = {}
        if defined?(Rails)
          path = Rails.root.join('config',"oubliette_api.yml")
          if File.exists? path
            config = YAML.load_file(path)[Rails.env] || {}
          end
        end
        config
      end
    end
  end
end
