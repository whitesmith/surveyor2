module Surveyor
  class Dependency < ActiveRecord::Base
    include Surveyor::Models::DependencyMethods
  end
end
