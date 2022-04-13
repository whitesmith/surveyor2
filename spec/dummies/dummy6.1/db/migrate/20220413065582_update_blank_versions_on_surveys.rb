# encoding: UTF-8
class Surveyor::Survey < ActiveRecord::Base; end
class UpdateBlankVersionsOnSurveys < ActiveRecord::Migration[6.1]
  def self.up
    Surveyor::Survey.where('survey_version IS ?', nil).each do |s|
      s.survey_version = 0
      s.save!
    end
  end

  def self.down
  end
end
