require 'rails/generators'

class Surveyor::ControllersGenerator < Rails::Generators::Base
  source_root File.expand_path('../../../../app/controllers', __FILE__)
  desc 'Install default controllers'

  def install
    directory 'surveyor', 'app/controllers/surveyor'
  end
end
