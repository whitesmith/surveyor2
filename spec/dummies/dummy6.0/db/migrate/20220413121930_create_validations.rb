# encoding: UTF-8
class CreateValidations < ActiveRecord::Migration[6.0]
  def self.up
    create_table :surveyor_validations do |t|
      # Context
      t.integer :answer_id # the answer to validate

      # Conditional
      t.string :rule

      # Message
      t.string :message

      t.timestamps
    end
  end

  def self.down
    drop_table :surveyor_validations
  end
end
