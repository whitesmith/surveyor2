require 'rails/generators'

class Surveyor::ViewsGenerator < Rails::Generators::Base
  source_root File.expand_path('../../../../app/views', __FILE__)
  desc 'Install default views'

  def install
    directory 'surveyor', 'app/views/surveyor'
    directory 'layouts/surveyor', 'app/views/layouts/surveyor'
  end
end
