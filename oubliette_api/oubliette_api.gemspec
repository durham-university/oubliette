$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "oubliette/api/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "oubliette_api"
  s.version     = Oubliette::API::VERSION
  s.authors     = ["Olli Lyytinen"]
  s.email       = ["olli.lyytinen@durham.ac.uk"]
  s.homepage    = "https://source.dur.ac.uk/university-library/Oubliette"
  s.summary     = "REST based API for other Rails apps to interface with Oubliette"
  s.description = "REST based API for other Rails apps to interface with Oubliette"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "httmultiparty"
  s.add_dependency "rails"

  s.add_development_dependency 'rspec'
end
