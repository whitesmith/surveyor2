# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)

require 'rspec/rails'
require 'factory_girl'
require 'factories'
require 'database_cleaner'
require 'shoulda/matchers'

require 'byebug'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

# Make sure migrations are up to date
ActiveRecord::Migration.check_pending!

Rails.logger.info "==== Ruby version: #{RUBY_VERSION}"
Rails.logger.info "==== Rails version: #{Rails.version}"

Rails.backtrace_cleaner.remove_silencers!

RSpec.configure do |config|
  config.before do |example|
    DatabaseCleaner.strategy  = :transaction
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Set fixture surveys path
TEST_SURVEYS_PATH = "#{File.dirname(__FILE__)}/fixtures/surveys".freeze
