# encoding: UTF-8
class AddIndexToSurveys < ActiveRecord::Migration[6.1]
  def self.up
    add_index(:surveyor_surveys, :access_code, :name => 'surveys_ac_idx')
  end

  def self.down
    remove_index(:surveyor_surveys, :name => 'surveys_ac_idx')
  end
end
