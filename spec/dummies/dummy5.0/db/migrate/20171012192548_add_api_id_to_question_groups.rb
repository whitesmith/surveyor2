# encoding: UTF-8
class AddApiIdToQuestionGroups < ActiveRecord::Migration[5.0]
  def self.up
    add_column :surveyor_question_groups, :api_id, :string
  end

  def self.down
    remove_column :surveyor_question_groups, :api_id
  end
end
