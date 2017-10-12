# encoding: UTF-8
class AddDisplayOrderToSurveys < ActiveRecord::Migration<%= migration_version %>
  def self.up
    add_column :surveyor_surveys, :display_order, :integer
  end

  def self.down
    remove_column :surveyor_surveys, :display_order
  end
end
