# encoding: UTF-8
class AddUniqueIndicies < ActiveRecord::Migration
  def self.up
    remove_index(:surveyor_response_sets, :name => 'response_sets_ac_idx')
    add_index(:surveyor_response_sets, :access_code, :name => 'response_sets_ac_idx', :unique => true)

    remove_index(:surveyor_surveys, :name => 'surveys_ac_idx')
    add_index(:surveyor_surveys, :access_code, :name => 'surveys_ac_idx', :unique => true)
  end

  def self.down
    remove_index(:surveyor_response_sets, :name => 'response_sets_ac_idx')
    add_index(:surveyor_response_sets, :access_code, :name => 'response_sets_ac_idx')

    remove_index(:surveyor_surveys, :name => 'surveys_ac_idx')
    add_index(:surveyor_surveys, :access_code, :name => 'surveys_ac_idx')
  end
end
