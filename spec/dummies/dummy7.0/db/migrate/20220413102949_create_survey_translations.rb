# encoding: UTF-8
class CreateSurveyTranslations < ActiveRecord::Migration[7.0]
  def self.up
    create_table :surveyor_survey_translations do |t|
      # Content
      t.integer :survey_id

      # Reference
      t.string :locale
      t.text :translation

      t.timestamps
    end
  end

  def self.down
    drop_table :surveyor_survey_translations
  end
end
