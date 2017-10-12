module Surveyor
  class ValidationCondition < ActiveRecord::Base
    include Surveyor::Models::ValidationConditionMethods
  end
end
