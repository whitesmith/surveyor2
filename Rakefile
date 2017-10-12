begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'rails/version'

require 'rdoc/task'
require 'rspec/core/rake_task'

task default: :spec

desc "Generate all rdoc"
RDoc::Task.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Surveyor'
  rdoc.options << '--line-numbers'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Run all specs"
RSpec::Core::RakeTask.new(:spec) do |config|
  config.verbose = false
end

namespace :surveyor do
  desc "Generate migrations on dummy app"
  task :migration do
    cd "spec/dummies/dummy#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
    system "BUNDLE_GEMFILE=/code/gemfiles/rails#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}.gemfile bundle exec rails g surveyor:migration"
  end
end

Bundler::GemHelper.install_tasks
