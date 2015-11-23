module Oubliette
  class Engine < ::Rails::Engine
    isolate_namespace Oubliette

    config.autoload_paths += %W(#{config.root}/app/jobs/concerns #{config.root}/app/actors/concerns #{config.root}/app/forms/concerns #{config.root}/app/presenters/concerns)

    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
  end
end
