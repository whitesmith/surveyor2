$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "surveyor/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "surveyor2"
  s.version     = Surveyor::VERSION
  s.authors     = ["Alexandre Jesus"]
  s.email       = ["adbjesus@whitesmith.co"]
  s.homepage    = "https://github.com/whitesmith/surveyor2"
  s.summary     = "Summary of Surveyor2."
  s.description = "Description of Surveyor2."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.required_ruby_version = ">= 2.7.0"

  s.add_dependency "rails", ">= 5.1"
  s.add_dependency "uuidtools", "~>2.1.5"
  s.add_dependency "mustache"
  s.add_dependency "rabl"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "appraisal"
  s.add_development_dependency "factory_bot"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "byebug"
  s.add_development_dependency "rubocop"
end
