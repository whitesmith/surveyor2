# encoding: UTF-8
class AddVersionToSurveys < ActiveRecord::Migration<%= migration_version %>
  def self.up
    add_column :surveyor_surveys, :survey_version, :integer, :default => 0
  end

  def self.down
    remove_column :surveyor_surveys, :survey_version
  end
end
