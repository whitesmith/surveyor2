require 'rails/generators/active_record'

class Surveyor::MigrationsGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  
  source_root File.expand_path('../templates', __FILE__)
  desc 'Instal Surveyor migrations'

  SURVEYOR_MIGRATIONS = %w(
    create_surveys
    create_survey_sections
    create_questions
    create_question_groups create_answers
    create_response_sets
    create_responses
    create_dependencies
    create_dependency_conditions
    create_validations
    create_validation_conditions
    add_display_order_to_surveys
    add_correct_answer_id_to_questions
    add_index_to_response_sets
    add_index_to_surveys
    add_unique_indicies
    add_section_id_to_responses
    add_default_value_to_answers
    add_api_ids
    add_display_type_to_answers
    add_api_id_to_question_groups
    add_api_ids_to_response_sets_and_responses
    update_blank_api_ids_on_question_group
    drop_unique_index_on_access_code_in_surveys
    add_version_to_surveys
    add_unique_index_on_access_code_and_version_in_surveys
    update_blank_versions_on_surveys
    api_ids_must_be_unique
    create_survey_translations
    add_input_mask_attributes_to_answer
  )

  def install
    SURVEYOR_MIGRATIONS.each do |name|
      migration_template(
        "db/migrate/#{name}.rb",
        "db/migrate/#{name}.rb",
        migration_version: migration_version
      )
    end
  end
  
  def self.next_migration_number(dirname)
    ActiveRecord::Generators::Base.next_migration_number(dirname)
  end

  private

  def migration_version
    if Rails.version >= "5.0.0"
      "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
    end
  end
end
