# encoding: UTF-8
class AddUniqueIndexOnAccessCodeAndVersionInSurveys < ActiveRecord::Migration[5.0]
  def self.up
    add_index(:surveyor_surveys, [ :access_code, :survey_version], :name => 'surveys_access_code_version_idx', :unique => true)
  end

  def self.down
    remove_index( :surveyor_surveys, :name => 'surveys_access_code_version_idx' )
  end
end
