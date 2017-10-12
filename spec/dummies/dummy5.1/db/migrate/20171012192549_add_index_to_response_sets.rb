# encoding: UTF-8
class AddIndexToResponseSets < ActiveRecord::Migration[5.1]
  def self.up
    add_index(:surveyor_response_sets, :access_code, :name => 'response_sets_ac_idx')
  end

  def self.down
    remove_index(:surveyor_response_sets, :name => 'response_sets_ac_idx')
  end
end
