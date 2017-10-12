# encoding: UTF-8
class AddApiIds < ActiveRecord::Migration
  def self.up
    add_column :surveyor_surveys, :api_id, :string
    add_column :surveyor_questions, :api_id, :string
    add_column :surveyor_answers, :api_id, :string
  end

  def self.down
    remove_column :surveyor_surveys, :api_id
    remove_column :surveyor_questions, :api_id
    remove_column :surveyor_answers, :api_id
  end
end
