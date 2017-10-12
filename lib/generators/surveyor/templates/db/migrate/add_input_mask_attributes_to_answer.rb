# encoding: UTF-8
class AddInputMaskAttributesToAnswer < ActiveRecord::Migration<%= migration_version %>
  def self.up
    add_column :surveyor_answers, :input_mask, :string
    add_column :surveyor_answers, :input_mask_placeholder, :string
  end

  def self.down
    remove_column :surveyor_answers, :input_mask
    remove_column :surveyor_answers, :input_mask_placeholder
  end
end
