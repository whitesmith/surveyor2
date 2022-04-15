require 'spec_helper'

describe Surveyor::Dependency, type: :model do
  subject(:dependency) { FactoryBot.create(:dependency) }

  it { should be_valid }
  it { should validate_presence_of(:rule) }
  it { should validate_numericality_of(:question_id) }
  it { should validate_numericality_of(:question_group_id) }
  it { should allow_values('A', 'B', 'A and B', 'A or B', '!A', '!(A)', '(A and B)', '(A and B or C) or (D and (B or C))', '(((A and B) or C) or D) and E').for(:rule) }
  it { should_not allow_values('', 'foo', '1 to 2', 'a and b', '(A', 'A)', 'A!', 'A)!', 'A (A and B)', '(A) B', '(A) (B)').for(:rule) }

  it 'should alias question_id as dependent_question_id' do
    dependency.question_id = 19
    expect(dependency.dependent_question_id).to eq(19)
    dependency.dependent_question_id = 14
    expect(dependency.question_id).to eq(14)
  end

  context 'when evaluating dependency conditions of a question in a response set' do
    shared_examples 'a boolean rule matcher' do |rule, responses, result|
      let(:question) { FactoryBot.create(:question) }
      let(:dependency) { FactoryBot.create(:dependency, question: question, rule: rule) }
      let(:response_set) { FactoryBot.create(:response_set, survey: question.survey_section.survey) }

      before(:each) do
        responses.each do |key, value|
          answer = FactoryBot.create(:answer, question: question, response_class: 'string')
          FactoryBot.create(:response, question: question, answer: answer, response_set: response_set, string_value: 'true')
          FactoryBot.create(:dependency_condition, question: question, dependency: dependency, answer: answer, rule_key: key.to_s, operator: '==', string_value: value.to_s)
        end

        response_set.reload
        dependency.reload
      end

      it 'should know if dependencies are met' do
        expect(dependency.is_met?(response_set)).to eq(result)
      end

      it 'should return correct response_set' do
        expect(dependency.conditions_hash(response_set)).to eq(responses)
      end
    end

    it_should_behave_like 'a boolean rule matcher', 'A', { A: true }, true
    it_should_behave_like 'a boolean rule matcher', 'A', { A: false }, false
    it_should_behave_like 'a boolean rule matcher', '!A', { A: true }, false
    it_should_behave_like 'a boolean rule matcher', '!(A)', { A: false }, true
    it_should_behave_like 'a boolean rule matcher', 'A and B', { A: true, B: true }, true
    it_should_behave_like 'a boolean rule matcher', 'A and B', { A: false, B: true }, false
    it_should_behave_like 'a boolean rule matcher', 'A and B', { A: true, B: false }, false
    it_should_behave_like 'a boolean rule matcher', 'A and B', { A: false, B: false }, false
    it_should_behave_like 'a boolean rule matcher', 'A and !B', { A: true, B: false }, true
    it_should_behave_like 'a boolean rule matcher', '!(A and B)', { A: false, B: false }, true
    it_should_behave_like 'a boolean rule matcher', 'A or B', { A: true, B: true }, true
    it_should_behave_like 'a boolean rule matcher', 'A or B', { A: false, B: true }, true
    it_should_behave_like 'a boolean rule matcher', 'A or B', { A: true, B: false }, true
    it_should_behave_like 'a boolean rule matcher', 'A or B', { A: false, B: false }, false
    it_should_behave_like 'a boolean rule matcher', '(A and B) or C', { A: true, B: false, C: true }, true
    it_should_behave_like 'a boolean rule matcher', '(A or B) and C', { A: true, B: false, C: false }, false
    it_should_behave_like 'a boolean rule matcher', 'A or (B and C)', { A: true, B: false, C: false }, true
    it_should_behave_like 'a boolean rule matcher', 'A or B and C', { A: true, B: false, C: false }, false
  end

  context 'with conditions' do
    let(:dependency_condition1) { FactoryBot.create(:dependency_condition, dependency: dependency, rule_key: 'A') }
    let(:dependency_condition2) { FactoryBot.create(:dependency_condition, dependency: dependency, rule_key: 'B') }
    let(:dependency_condition3) { FactoryBot.create(:dependency_condition, dependency: dependency, rule_key: 'C') }

    it 'should destroy conditions when destroyed' do
      dc_ids = dependency.dependency_conditions.map(&:id)
      dependency.destroy
      dc_ids.each do |id|
        expect(DependencyCondition.find_by_id(id)).to be_nil
      end
    end
  end
end
