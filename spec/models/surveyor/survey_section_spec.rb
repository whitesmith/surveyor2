require 'spec_helper'
require 'yaml'

describe Surveyor::SurveySection, type: :model do
  subject(:survey_section) { FactoryGirl.create(:survey_section) }

  it { should be_valid }
  it { should validate_presence_of(:title) }

  context 'with questions' do
    let(:question_1) { FactoryGirl.create(:question, survey_section: survey_section, display_order: 3, text: 'Peep') }
    let(:question_2) { FactoryGirl.create(:question, survey_section: survey_section, display_order: 1, text: 'Little') }
    let(:question_3) { FactoryGirl.create(:question, survey_section: survey_section, display_order: 2, text: 'Bo') }

    before(:each) do
      [question_1, question_2, question_3].each do |q|
        survey_section.questions << q
      end
    end

    it 'should have 3 questions' do
      expect(survey_section.questions.count).to eq(3)
    end

    it 'gets questions in order' do
      expect(survey_section.questions.order('display_order asc')).to eq([question_2, question_3, question_1])
      expect(survey_section.questions.order('display_order asc').map(&:display_order)).to eq([1, 2, 3])
    end

    it 'deletes child questions when deleted' do
      question_ids = survey_section.questions.map(&:id)
      survey_section.destroy
      question_ids.each { |id| expect(Surveyor::Question.find_by_id(id)).to be_nil }
    end
  end

  context 'with translations' do
    let(:survey) { FactoryGirl.create(:survey) }
    let(:survey_translation) do
      FactoryGirl.create(:survey_translation, locale: :es, translation: {
        survey_sections: {
          one: {
            title: 'Uno'
          }
        }
      }.to_yaml)
    end

    before do
      survey_section.reference_identifier = 'one'
      survey_section.survey = survey
      survey.translations << survey_translation
    end

    it 'returns its own translation' do
      expect(YAML.safe_load(survey_translation.translation, [Symbol])).not_to be_nil
      expect(survey_section.translation(:es)[:title]).to eq('Uno')
    end

    it 'returns its own default values' do
      expect(survey_section.translation(:de)).to eq('title' => survey_section.title, 'description' => survey_section.description)
    end
  end
end
