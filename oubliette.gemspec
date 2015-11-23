$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "oubliette/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "oubliette"
  s.version     = Oubliette::VERSION
  s.authors     = ["Olli Lyytinen"]
  s.email       = ["olli.lyytinen@durham.ac.uk"]
  s.homepage    = "https://source.dur.ac.uk/university-library/Oubliette"
  s.summary     = "Oubliette, digital preservation module"
  s.description = "Oubliette, digital preservation module"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 4.2.4"
  # Use SCSS for stylesheets
  s.add_dependency 'sass-rails', '~> 5.0'
  # Use jquery as the JavaScript library
  s.add_dependency 'jquery-rails'
  # Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
  s.add_dependency 'jbuilder', '~> 2.0'
  # Use Bootstrap
  s.add_dependency 'bootstrap-sass', '~> 3.3.5'
  s.add_dependency 'bootstrap-sass-extras'

  s.add_dependency 'rubyzip'
  s.add_dependency 'simple_form', '~> 3.1.0'

  s.add_dependency 'devise'
  s.add_dependency 'devise_ldap_authenticatable'
  s.add_dependency 'cancancan', '~> 1.10'

  s.add_dependency 'rsolr', '~> 1.0.6'
  s.add_dependency 'active-fedora'
  s.add_dependency 'hydra-editor', '~> 1.1.0'

  s.add_dependency 'resque'
  s.add_dependency 'resque-pool'

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'database_cleaner'
end
