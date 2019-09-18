module Oubliette
  module API
    module ModelBase
      extend ActiveSupport::Concern

      included do
        include ::HTTMultiParty
        include DurhamRails::API::Authentication
        base_uri Oubliette::API.config.fetch('base_url','http://localhost:3000/oubliette')
        read_timeout 300 # seconds

        class << self
          def local_mode?
            @local_mode ||= Oubliette::API.config.fetch('local_mode', false)
          end
        end

        attr_accessor :id
        attr_accessor :title
      end

      def initialize(user)
        @user = user
      end

      def local_mode?
        self.class.local_mode?
      end

      def as_json(*args)
        json = {'id' => id, 'title' => title}
        json
      end

      def to_json(*args)
        as_json.to_json(*args)
      end

      def parse_json(json)
        from_json(JSON.parse(json))
      end

      def from_json(json)
        @id = json['id']
        @title = json['title']
      end

      def fetch
        return local_fetch if local_mode?
        response = self.class.get(fetch_url, get_options)
        raise Oubliette::API::FetchError, "Error fetching object \"#{fetch_url}\": #{response.code} - #{response.message}" unless response.code == 200
        parse_json( response.body )
        self
      end
      
      def destroy
        return local_destroy if local_mode?
        response = self.class.delete(fetch_url)
        raise Oubliette::API::FetchError, "Error destroying object \"#{fetch_url}\": #{response.code} - #{response.message}" unless response.code == 200
        return true
      end

      def get_options
        self.class.get_options(@user)
      end

      def post_options
        get_options
      end

      module ClassMethods
        def from_json(json, user)
          self.new(user).tap do |instance|
            instance.from_json(json)
          end
        end

        def get_options(user)
          {query: {user: user}}
        end

        def post_options(user)
          self.get_options(user)
        end

        def parse_json(json, user)
          self.from_json(JSON.parse(json), user)
        end

        def find(id, user)
          obj = self.new(user)
          obj.id = id
          obj.fetch
        end

        def try_find(id, user)
          begin
            find(id, user)
          rescue Oubliette::API::FetchError => e
            nil
          end
        end

        def local_class
          "Oubliette::#{model_name.singularize.camelize}".constantize
        end

        def model_name
          raise 'Implement this in subclasses'
        end
      end

      def model_name
        self.class.model_name
      end

      def local_class
        self.class.local_class
      end

      private
      
        def local_destroy
          begin
            obj = local_class.find(id)
            obj.destroy
            return true
          rescue StandardError => e
            raise Oubliette::API::FetchError, "Error doing a local_destroy for #{model_name} #{id}"
          end
        end

        def local_fetch
          begin
            obj = local_class.find(id)
            self.from_json(obj.as_json(include_children: true))
            self
          rescue StandardError => e
            raise Oubliette::API::FetchError, "Error doing a local_fetch for #{model_name} #{id}"
          end
        end

        def fetch_url
          "/#{self.model_name}/#{CGI.escape id}.json"
        end

    end
  end
end
