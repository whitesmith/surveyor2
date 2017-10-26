module Surveyor
  class Engine < ::Rails::Engine
    isolate_namespace Surveyor

    config.to_prepare do
      Dir.glob(Rails.root + "app/models/surveyor/*.rb").each do |c|
        require_dependency(c)
      end
    end
  end
end
