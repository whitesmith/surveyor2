# encoding: UTF-8
class AddDefaultValueToAnswers < ActiveRecord::Migration[7.0]
  def self.up
    add_column :surveyor_answers, :default_value, :string
  end

  def self.down
    remove_column :surveyor_answers, :default_value
  end
end
