# encoding: UTF-8
class AddApiIdsToResponseSetsAndResponses < ActiveRecord::Migration
  def self.up
    add_column :surveyor_response_sets, :api_id, :string
    add_column :surveyor_responses, :api_id, :string
  end

  def self.down
    remove_column :surveyor_response_sets, :api_id
    remove_column :surveyor_responses, :api_id
  end
end
