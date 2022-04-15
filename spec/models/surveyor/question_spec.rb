require 'spec_helper'
require 'mustache'
require 'yaml'

describe Surveyor::Question, type: :model do
  subject(:question) { FactoryBot.create(:question) }

  it { should be_valid }
  it { should validate_presence_of(:text) }

  context 'when creating' do
    it '#is_mandantory == false by default' do
      expect(question.mandatory?).to be_falsy
    end

    it 'converts #pick to string' do
      expect(question.pick).to eq('none')
      question.pick = :one
      expect(question.pick).to eq('one')
      question.pick = nil
      expect(question.pick).to eq(nil)
    end

    it "#renderer == 'default' when #display_type = nil" do
      question.display_type = nil
      expect(question.renderer).to eq(:default)
    end

    it 'has #api_id with 36 characters by default' do
      expect(question.api_id.length).to eq(36)
    end

    it '#part_of_group? and #solo? are aware of question groups' do
      question.question_group = FactoryBot.create(:question_group)
      expect(question.solo?).to be_falsy
      expect(question.part_of_group?).to be_truthy

      question.question_group = nil
      expect(question.solo?).to be_truthy
      expect(question.part_of_group?).to be_falsy
    end
  end

  context 'with answers' do
    let(:answer_1) { FactoryBot.create(:answer, question: question, display_order: 3, text: 'blue') }
    let(:answer_2) { FactoryBot.create(:answer, question: question, display_order: 1, text: 'red') }
    let(:answer_3) { FactoryBot.create(:answer, question: question, display_order: 2, text: 'green') }

    before(:each) do
      [answer_1, answer_2, answer_3].each { |a| question.answers << a }
    end

    it 'should have 3 answers' do
      expect(question.answers.count).to eq(3)
    end

    it 'gets answers in order' do
      expect(question.answers.order('display_order asc')).to eq([answer_2, answer_3, answer_1])
      expect(question.answers.order('display_order asc').map(&:display_order)).to eq([1, 2, 3])
    end

    it 'deletes child answers when deleted' do
      answer_ids = question.answers.map(&:id)
      question.destroy
      answer_ids.each { |id| expect(Surveyor::Answer.find_by_id(id)).to be_nil }
    end
  end

  context 'with dependencies' do
    let(:response_set) { FactoryBot.create(:response_set) }
    let(:dependency) { FactoryBot.create(:dependency) }

    before(:each) do
      question.dependency = dependency
      allow(dependency).to receive(:is_met?).with(response_set) { true }
    end

    it 'checks its dependency' do
      expect(question.triggered?(response_set)).to be_truthy
    end

    it 'deletes its dependency when deleted' do
      d_id = question.dependency.id
      question.destroy
      expect(Surveyor::Dependency.find_by_id(d_id)).to be_nil
    end
  end

  context 'with mustache text substitution' do
    let(:mustache_context) do
      Class.new(::Mustache) do
        def site
          'Northwestern'
        end

        def foo
          'bar'
        end
      end
    end

    it 'subsitutes Mustache context variables' do
      question.text = 'You are in {{site}}'
      expect(question.in_context(question.text, mustache_context)).to eq('You are in Northwestern')
    end

    it 'substitues in views' do
      question.text = 'You are in {{site}}'
      expect(question.text_for(nil, mustache_context)).to eq('You are in Northwestern')
    end
  end

  context 'with translations' do
    let(:survey) { FactoryBot.create(:survey) }
    let(:survey_section) { FactoryBot.create(:survey_section) }
    let(:survey_translation) do
      FactoryBot.create(:survey_translation, locale: :es, translation: {
        questions: {
          hello: {
            text: '¡Hola!'
          }
        }
      }.to_yaml)
    end

    before(:each) do
      question.reference_identifier = 'hello'
      question.survey_section = survey_section
      survey_section.survey = survey
      survey.translations << survey_translation
    end

    it 'returns its own translation' do
      expect(YAML.safe_load(survey_translation.translation, permitted_classes: [Symbol])).not_to be_nil
      expect(question.translation(:es)[:text]).to eq('¡Hola!')
    end

    it 'returns its own default values' do
      expect(question.translation(:de)).to eq('text' => question.text, 'help_text' => question.help_text)
    end

    it 'returns translations in views' do
      expect(question.text_for(nil, nil, :es)).to eq('¡Hola!')
    end

    it 'returns default values in views' do
      expect(question.text_for(nil, nil, :de)).to eq(question.text)
    end
  end

  context 'handling strings' do
    it '#split preserves strings' do
      expect(question.split(question.text)).to eq('What is your favorite color?')
    end

    it '#split(:pre) preserves strings' do
      expect(question.split(question.text, :pre)).to eq('What is your favorite color?')
    end

    it '#split(:post) preserves strings' do
      expect(question.split(question.text, :post)).to eq('')
    end

    it '#split splits strings' do
      question.text = 'before|after|extra'
      expect(question.split(question.text)).to eq('before|after|extra')
    end

    it '#split(:pre) splits strings' do
      question.text = 'before|after|extra'
      expect(question.split(question.text, :pre)).to eq('before')
    end

    it '#split(:post) splits strings' do
      question.text = 'before|after|extra'
      expect(question.split(question.text, :post)).to eq('after|extra')
    end
  end

  context 'for views' do
    it '#text_for with #display_type == image' do
      question.text = 'rails.png'
      question.display_type = :image
      expect(question.text_for).to match(/<img (src="\/(images|assets)\/rails(-[a-f0-9]+)?\.png")|(src="\/(images|assets)\/rails(-[a-f0-9]+)?\.png") \/>/)
    end

    it '#help_text_for' do
      question.help_text = 'bar'
      expect(question.help_text_for).to eq('bar')
    end

    it '#text_for preserves strings' do
      expect(question.text_for).to eq('What is your favorite color?')
    end

    it '#text_for(:pre) preserves strings' do
      expect(question.text_for(:pre)).to eq('What is your favorite color?')
    end

    it '#text_for(:post) preserves strings' do
      expect(question.text_for(:post)).to eq('')
    end

    it '#text_for splits strings' do
      question.text = 'before|after|extra'
      expect(question.text_for).to eq('before|after|extra')
    end

    it '#text_for(:pre) splits strings' do
      question.text = 'before|after|extra'
      expect(question.text_for(:pre)).to eq('before')
    end

    it '#text_for(:post) splits strings' do
      question.text = 'before|after|extra'
      expect(question.text_for(:post)).to eq('after|extra')
    end
  end
end
