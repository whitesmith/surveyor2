require 'rails/generators'

class Surveyor::ExampleSurveyGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  desc 'Install example survey'

  def install
    copy_file 'surveys/quiz.rb'
    directory 'surveys/translations'
  end
end
