# encoding: UTF-8
class AddCorrectAnswerIdToQuestions < ActiveRecord::Migration<%= migration_version %>
  def self.up
    add_column :surveyor_questions, :correct_answer_id, :integer
  end

  def self.down
    remove_column :surveyor_questions, :correct_answer_id
  end
end
