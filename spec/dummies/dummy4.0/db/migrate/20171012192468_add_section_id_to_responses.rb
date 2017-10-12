# encoding: UTF-8
class AddSectionIdToResponses < ActiveRecord::Migration
  def self.up
    add_column :surveyor_responses, :survey_section_id, :integer
    add_index :surveyor_responses, :survey_section_id
  end

  def self.down
    remove_index :surveyor_responses, :survey_section_id
    remove_column :surveyor_responses, :survey_section_id
  end
end
