# encoding: UTF-8
class DropUniqueIndexOnAccessCodeInSurveys < ActiveRecord::Migration[5.0]
  def self.up
    remove_index( :surveyor_surveys, :name => 'surveys_ac_idx' )
  end

  def self.down
    add_index(:surveyor_surveys, :access_code, :name => 'surveys_ac_idx')
  end
end
