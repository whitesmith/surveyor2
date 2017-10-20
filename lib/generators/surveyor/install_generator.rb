require 'rails/generators'

class Surveyor::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path('../../../../config/locales', __FILE__)
  desc 'Install Surveyor'

  def install
    copy_file 'en.yml', 'config/locales/surveyor.en.yml'
    route "mount Surveyor::Engine => '/surveys', as: 'surveyor'"
  end
end
