require 'spec_helper'
require 'yaml'

describe Surveyor::QuestionGroup, type: :model do
  subject(:question_group) { FactoryBot.create(:question_group) }

  it { should be_valid }

  context 'when creating' do
    it '#display_type = inline by default' do
      expect(question_group.display_type).to eq('inline')
      expect(question_group.renderer).to eq(:inline)
    end

    it "#renderer == 'default' when #display_type = nil" do
      question_group.display_type = nil
      expect(question_group.renderer).to eq(:default)
    end

    it 'interprets symbolizes #display_type to #renderer' do
      question_group.display_type = 'foo'
      expect(question_group.renderer).to eq(:foo)
    end

    it 'reports DOM ready #css_class based on dependencies' do
      dependency = FactoryBot.create(:dependency)
      response_set = FactoryBot.create(:response_set)

      question_group.dependency = dependency
      expect(dependency).to receive(:is_met?).with(response_set) { true }
      expect(question_group.css_class(response_set)).to eq('g_dependent')

      expect(dependency).to receive(:is_met?).with(response_set) { false }
      expect(question_group.css_class(response_set)).to eq('g_dependent g_hidden')

      question_group.custom_class = 'foo bar'
      expect(dependency).to receive(:is_met?).with(response_set) { false }
      expect(question_group.css_class(response_set)).to eq('g_dependent g_hidden foo bar')
    end
  end

  context 'with translations' do
    let(:survey_translation) do
      FactoryBot.create(:survey_translation, locale: :es, translation: {
        question_groups: {
          goodbye: {
            text: '¡Adios!'
          }
        }
      }.to_yaml)
    end

    let(:survey) { FactoryBot.create(:survey) }
    let(:survey_section) { FactoryBot.create(:survey_section) }
    let(:question) { FactoryBot.create(:question) }

    before(:each) do
      question_group.text = 'Goodbye'
      question_group.reference_identifier = 'goodbye'
      question_group.questions = [question]
      question.survey_section = survey_section
      survey_section.survey = survey
      survey.translations << survey_translation
    end

    it 'returns its own translation' do
      expect(question_group.translation(:es)[:text]).to eq('¡Adios!')
    end

    it 'returns its own default values' do
      expect(question_group.translation(:de)).to eq('text' => 'Goodbye', 'help_text' => nil)
    end
  end
end
