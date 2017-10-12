# encoding: UTF-8
class AddIndexToSurveys < ActiveRecord::Migration<%= migration_version %>
  def self.up
    add_index(:surveyor_surveys, :access_code, :name => 'surveys_ac_idx')
  end

  def self.down
    remove_index(:surveyor_surveys, :name => 'surveys_ac_idx')
  end
end
