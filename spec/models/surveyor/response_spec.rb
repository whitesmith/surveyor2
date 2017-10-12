require 'spec_helper'

describe Surveyor::Response, type: :model do
  subject(:response) { FactoryGirl.create(:response) }

  it { should be_valid }
  it { should validate_presence_of(:question_id) }
  it { should validate_presence_of(:answer_id) }

  it 'should be correct if the question has no correct_answer_id' do
    expect(response.question.correct_answer_id).to be_nil
    expect(response.correct?).to be_truthy
  end

  it "should be correct if the answer's response class != answer" do
    expect(response.answer.response_class).not_to eq('answer')
    expect(response.correct?).to be_truthy
  end

  it "should be (in)correct if answer_id is (not) equal to question's correct_answer_id" do
    response.answer.response_class = 'answer'
    response.question.correct_answer = response.answer
    expect(response.correct?).to be_truthy

    response.answer = FactoryGirl.create(:answer, response_class: 'answer')
    expect(response.correct?).to be_falsy
  end

  it 'should be in order by created_at' do
    expect(response.response_set).not_to be_nil
    response2 = FactoryGirl.create(:response, response_set: response.response_set, created_at: (response.created_at + 1))
    expect(Surveyor::Response.all).to eq([response, response2])
  end

  context 'returns the response as the type requested' do
    it "returns 'string'" do
      response.string_value = 'blah'
      expect(response.as('string')).to eq('blah')
      expect(response.as(:string)).to eq('blah')
    end

    it "returns 'integer'" do
      response.integer_value = 1001
      expect(response.as(:integer)).to eq(1001)
    end

    it "returns 'float'" do
      response.float_value = 3.14
      expect(response.as(:float)).to eq(3.14)
    end

    it "returns 'answer'" do
      response.answer_id = 14
      expect(response.as(:answer)).to eq(14)
    end

    it 'default returns answer type if not specified' do
      response.answer_id = 18
      expect(response.as(:stuff)).to eq(18)
    end

    it 'returns empty elements if the response is cast as a type that is not present' do
      resp = Surveyor::Response.new(question_id: 314, response_set_id: 156)
      expect(resp.as(:string)).to be_nil
      expect(resp.as(:integer)).to be_nil
      expect(resp.as(:float)).to be_nil
      expect(resp.as(:answer)).to be_nil
      expect(resp.as(:stuff)).to be_nil
    end
  end

  describe 'applicable_attributes' do
    let(:question) { FactoryGirl.create(:question, text: 'Who rules?') }
    let(:answer) { FactoryGirl.create(:answer, question: question, text: 'Odoyle', response_class: 'answer') }
    let(:answer_other) { FactoryGirl.create(:answer, question: question, text: 'Other', response_class: 'string') }

    it 'should have string_value if response_type is string' do
      good = { 'question_id' => question.id, 'answer_id' => answer_other.id, 'string_value' => 'Frank' }
      expect(Surveyor::Response.applicable_attributes(good)).to eq(good)
    end

    it 'should not have string_value if response_type is answer' do
      bad = { 'question_id' => question.id, 'answer_id' => answer.id, 'string_value' => 'Frank' }
      expect(Surveyor::Response.applicable_attributes(bad)).to eq('question_id' => question.id, 'answer_id' => answer.id)
    end

    it 'should have string_value if response_type is string and answer_id is an array (in the case of checkboxes)' do
      good = { 'question_id' => question.id, 'answer_id' => ['', answer.id], 'string_value' => 'Frank' }
      expect(Surveyor::Response.applicable_attributes(good)).to eq('question_id' => question.id, 'answer_id' => ['', answer.id])
    end

    it 'should have ignore attribute if missing answer_id' do
      ignore = { 'question_id' => question.id, 'answer_id' => '', 'string_value' => 'Frank' }
      expect(Surveyor::Response.applicable_attributes(ignore)).to eq('question_id' => question.id, 'answer_id' => '', 'string_value' => 'Frank')
    end

    it 'should have ignore attribute if missing answer_id is an array' do
      ignore = { 'question_id' => question.id, 'answer_id' => [''], 'string_value' => 'Frank' }
      expect(Surveyor::Response.applicable_attributes(ignore)).to eq('question_id' => question.id, 'answer_id' => [''], 'string_value' => 'Frank')
    end
  end

  context 'when datetime' do
    it "returns '' when nil" do
      response.answer.response_class = 'datetime'
      response.datetime_value = nil

      expect(response.to_formatted_s).to eq('')
    end
  end

  describe '#json_value' do
    context 'when integer' do
      let(:answer) { FactoryGirl.create(:answer, response_class: 'integer') }
      subject(:response) { FactoryGirl.create(:response, answer: answer, integer_value: 2) }

      it 'should be 2' do
        expect(response.json_value).to eq(2)
      end
    end

    context 'when float' do
      let(:answer) { FactoryGirl.create(:answer, response_class: 'float') }
      subject(:response) { FactoryGirl.create(:response, answer: answer, float_value: 3.14) }

      it 'should be 3.14' do
        expect(response.json_value).to eq(3.14)
      end
    end

    context 'when string' do
      let(:answer) { FactoryGirl.create(:answer, response_class: 'string') }
      subject(:response) { FactoryGirl.create(:response, answer: answer, string_value: 'bar') }

      it "should be 'bar'" do
        expect(response.json_value).to eq('bar')
      end
    end

    context 'when datetime' do
      let(:answer) { FactoryGirl.create(:answer, response_class: 'datetime') }
      subject(:response) { FactoryGirl.create(:response, answer: answer, datetime_value: DateTime.strptime('2010-04-08T10:30+00:00', '%Y-%m-%dT%H:%M%z')) }

      it "should be '2010-04-08T10:30+00:00'" do
        expect(response.json_value).to eq('2010-04-08T10:30+00:00')
      end
    end

    context 'when date' do
      let(:answer) { FactoryGirl.create(:answer, response_class: 'date') }
      subject(:response) { FactoryGirl.create(:response, answer: answer, datetime_value: DateTime.strptime('2010-04-08', '%Y-%m-%d')) }

      it "should be '2010-04-08'" do
        expect(response.json_value).to eq('2010-04-08')
      end
    end

    context 'when time' do
      let(:answer) { FactoryGirl.create(:answer, response_class: 'time') }
      subject(:response) { FactoryGirl.create(:response, answer: answer, datetime_value: DateTime.strptime('10:30', '%H:%M')) }

      it "should be '10:30'" do
        expect(response.json_value).to eq('10:30')
      end
    end
  end

  describe '#date_value=' do
    it 'accepts a parseable date string' do
      response.date_value = '2010-01-15'
      expect(response.datetime_value.strftime('%Y %m %d')).to eq('2010 01 15')
    end

    it 'clears when given nil' do
      response.datetime_value = Time.new
      response.date_value = nil
      expect(response.datetime_value).to be_nil
    end
  end

  describe 'time_value=' do
    it 'accepts a parseable time string' do
      response.time_value = '11:30'
      expect(response.datetime_value.strftime('%H %M %S')).to eq('11 30 00')
    end

    it 'clears when given nil' do
      response.datetime_value = Time.new
      response.time_value = nil
      expect(response.datetime_value).to be_nil
    end
  end
end
