begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)

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
Bundler::GemHelper.install_tasks
