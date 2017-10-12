module Surveyor
  class Survey < ActiveRecord::Base
    include Surveyor::Models::SurveyMethods
  end
end
