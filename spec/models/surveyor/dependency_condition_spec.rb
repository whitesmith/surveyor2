require 'spec_helper'

describe Surveyor::DependencyCondition, type: :model do
  subject(:dependency_condition) { FactoryBot.create(:dependency_condition) }

  it { should be_valid }
  it { should validate_presence_of(:operator) }
  it { should validate_presence_of(:rule_key) }
  it { should validate_uniqueness_of(:rule_key).scoped_to(:dependency_id) }
  it { should_not allow_values('=', '!', '#').for(:operator) }

  it do
    should allow_values(
      '==', '!=', '<', '>', '<=', '>=',
      'count==1', 'count!=1', 'count<1', 'count>1', 'count<=1', 'count>=1'
    ).for(:operator)
  end

  it do
    should_not allow_values(
      '#', '=', '!', '!!', '<>', '><', '=<', '=>',
      'count==', 'count!=', 'count<', 'count>', 'count<=', 'count>=',
      'count=1', 'count><1', 'count<>1', 'count=>1', 'count!1', 'count!!1', 'count=<1'
    ).for(:operator)
  end

  context 'class' do
    it 'should have a list of operators' do
      %w[== != < > <= >=].each do |operator|
        expect(Surveyor::DependencyCondition.operators).to include(operator)
      end
    end
  end

  it 'returns true for != with no responses' do
    question = FactoryBot.create(:question)
    rs = FactoryBot.create(:response_set)

    dependency_condition.update!(
      rule_key: 'C',
      question: question
    )

    expect(dependency_condition.to_hash(rs)).to eq(C: false)
  end

  it 'should not assume that Response#as is not nil' do
    answer = FactoryBot.create(:answer, response_class: :integer)
    question = answer.question
    response = FactoryBot.create(:response, answer: answer, question: question)
    response_set = response.response_set

    dependency_condition.update!(
      question: question,
      answer: answer,
      operator: '>',
      integer_value: 4,
      rule_key: 'A'
    )

    expect(response.integer_value).to be_nil
    expect(dependency_condition.to_hash(response_set)).to eq(A: false)
  end

  context 'operator' do
    shared_examples 'a dependency_condition operator' do |operator, result_equal, result_smaller, result_larger, result_checkbox_different|
      before(:each) do
        @a = FactoryBot.create(:answer, response_class: 'answer')
        @b = FactoryBot.create(:answer, question: @a.question)
        @r = FactoryBot.create(:response, question: @a.question, answer: @a)
        @rs = @r.response_set
        @dc = FactoryBot.create(
          :dependency_condition,
          question: @a.question,
          answer: @a,
          operator: operator,
          rule_key: 'A'
        )
      end

      it 'shoud equal response as answer' do
        expect(@dc.as(:answer)).to eq(@r.as(:answer))
      end

      it 'with checkbox/radio type response' do
        expect(@dc.to_hash(@rs)).to eq(A: result_equal)
        @dc.update!(answer: @b)
        expect(@dc.to_hash(@rs)).to eq(A: result_checkbox_different)
      end

      it 'with string value response' do
        @a.update!(response_class: 'string')
        @r.update!(string_value: 'hello123')
        @dc.update!(string_value: 'hello123')
        expect(@dc.to_hash(@rs)).to eq(A: result_equal)
        @r.update!(string_value: 'aaaa')
        expect(@dc.to_hash(@rs)).to eq(A: result_smaller)
        @r.update!(string_value: 'zzzz')
        expect(@dc.to_hash(@rs)).to eq(A: result_larger)
      end

      it 'with a text value response' do
        @a.update!(response_class: 'text')
        @r.update!(text_value: 'hello this is some text for comparison')
        @dc.update!(text_value: 'hello this is some text for comparison')
        expect(@dc.to_hash(@rs)).to eq(A: result_equal)
        @r.update!(text_value: 'aaaa')
        expect(@dc.to_hash(@rs)).to eq(A: result_smaller)
        @r.update!(text_value: 'zzzz')
        expect(@dc.to_hash(@rs)).to eq(A: result_larger)
      end

      it 'with an integer value response' do
        @a.update!(response_class: 'integer')
        @r.update!(integer_value: 1000)
        @dc.update!(integer_value: 1000)
        expect(@dc.to_hash(@rs)).to eq(A: result_equal)
        @r.update!(integer_value: 100)
        expect(@dc.to_hash(@rs)).to eq(A: result_smaller)
        @r.update!(integer_value: 10_000)
        expect(@dc.to_hash(@rs)).to eq(A: result_larger)
      end

      it 'with a float value response' do
        @a.update!(response_class: 'float')
        @r.update!(float_value: 100.1)
        @dc.update!(float_value: 100.1)
        expect(@dc.to_hash(@rs)).to eq(A: result_equal)
        @r.update!(float_value: 12.123)
        expect(@dc.to_hash(@rs)).to eq(A: result_smaller)
        @r.update!(float_value: 130.123)
        expect(@dc.to_hash(@rs)).to eq(A: result_larger)
      end
    end

    context '==' do
      it_should_behave_like 'a dependency_condition operator', '==', true, false, false, false
    end

    context '!=' do
      it_should_behave_like 'a dependency_condition operator', '!=', false, true, true, true
    end

    context '<' do
      it_should_behave_like 'a dependency_condition operator', '<', false, true, false, false
    end

    context '>' do
      it_should_behave_like 'a dependency_condition operator', '>', false, false, true, false
    end

    context '<=' do
      it_should_behave_like 'a dependency_condition operator', '<=', true, true, false, false
    end

    context '>=' do
      it_should_behave_like 'a dependency_condition operator', '>=', true, false, true, false
    end
  end

  context 'evaluating with response_class string' do
    it 'should compare answer ids when the dependency condition string_value is nil' do
      a = FactoryBot.create(:answer, response_class: 'string')
      r = FactoryBot.create(:response, question: a.question, answer: a, string_value: '')
      rs = r.response_set
      dc = FactoryBot.create(:dependency_condition, question: a.question, answer: a, operator: '==', rule_key: 'J')
      expect(dc.to_hash(rs)).to eq(J: true)
    end

    it 'should compare strings when the dependency condition string_value is not nil, even if it is blank' do
      a = FactoryBot.create(:answer, response_class: 'string')
      r = FactoryBot.create(:response, question: a.question, answer: a, string_value: 'foo')
      rs = r.response_set
      dc = FactoryBot.create(:dependency_condition, question: a.question, answer: a, operator: '==', rule_key: 'K', string_value: 'foo')
      expect(dc.to_hash(rs)).to eq(K: true)

      r.update(string_value: '')
      dc.string_value = ''
      expect(dc.to_hash(rs)).to eq(K: true)
    end
  end

  describe "evaluate 'count' operator" do
    let(:question) { FactoryBot.create(:question) }
    let(:answers) { FactoryBot.create_list(:answer, 3, question: question, response_class: 'answer') }
    let(:response_set) { FactoryBot.create(:response_set) }

    subject(:dependency_condition) { FactoryBot.create(:dependency_condition, question: question, rule_key: 'M') }

    before(:each) do
      answers.slice(0, 2).each do |a|
        FactoryBot.create(:response, question: question, answer: a, response_set: response_set)
      end
    end

    it 'with operator with >' do
      dependency_condition.operator = 'count>1'
      expect(dependency_condition.to_hash(response_set)).to eq(M: true)
      dependency_condition.operator = 'count>2'
      expect(dependency_condition.to_hash(response_set)).to eq(M: false)
      dependency_condition.operator = 'count>3'
      expect(dependency_condition.to_hash(response_set)).to eq(M: false)
    end

    it 'with operator with <' do
      dependency_condition.operator = 'count<1'
      expect(dependency_condition.to_hash(response_set)).to eq(M: false)
      dependency_condition.operator = 'count<2'
      expect(dependency_condition.to_hash(response_set)).to eq(M: false)
      dependency_condition.operator = 'count<3'
      expect(dependency_condition.to_hash(response_set)).to eq(M: true)
    end

    it 'with operator with <=' do
      dependency_condition.operator = 'count<=1'
      expect(dependency_condition.to_hash(response_set)).to eq(M: false)
      dependency_condition.operator = 'count<=2'
      expect(dependency_condition.to_hash(response_set)).to eq(M: true)
      dependency_condition.operator = 'count<=3'
      expect(dependency_condition.to_hash(response_set)).to eq(M: true)
    end

    it 'with operator with >=' do
      dependency_condition.operator = 'count>=1'
      expect(dependency_condition.to_hash(response_set)).to eq(M: true)
      dependency_condition.operator = 'count>=2'
      expect(dependency_condition.to_hash(response_set)).to eq(M: true)
      dependency_condition.operator = 'count>=3'
      expect(dependency_condition.to_hash(response_set)).to eq(M: false)
    end

    it 'with operator with >=' do
      dependency_condition.operator = 'count!=1'
      expect(dependency_condition.to_hash(response_set)).to eq(M: true)
      dependency_condition.operator = 'count!=2'
      expect(dependency_condition.to_hash(response_set)).to eq(M: false)
      dependency_condition.operator = 'count!=3'
      expect(dependency_condition.to_hash(response_set)).to eq(M: true)
    end
  end
end
