# encoding: UTF-8
class AddConditionTypeFieldsToDependencyConditions < ActiveRecord::Migration[7.0]
  def self.up
    add_column :surveyor_dependency_conditions, :condition_type, :string, default: 'default'
    add_column :surveyor_dependency_conditions, :logic_reference, :string
  end

  def self.down
    remove_column :surveyor_dependency_conditions, :condition_type
    remove_column :surveyor_dependency_conditions, :logic_reference
  end
end
