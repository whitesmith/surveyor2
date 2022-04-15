require 'spec_helper'

describe Surveyor::ValidationCondition, type: :model do
  subject(:validation_condition) { FactoryBot.create(:validation_condition) }

  it { should be_valid }
  it { should validate_presence_of(:operator) }
  it { should validate_presence_of(:rule_key) }
  it { should validate_inclusion_of(:operator).in_array(Surveyor::Common::OPERATORS) }
  it { should validate_uniqueness_of(:rule_key).scoped_to(:validation_id) }

  # this causes issues with building and saving
  # it "should be invalid without a parent validation_id" do
  #   @validation_condition.validation_id = nil
  #   @validation_condition.should have(1).errors_on(:validation_id)
  # end

  # TODO: Change to shared examples
  def test_var(vhash, ahash, rhash)
    v = FactoryBot.create(:validation_condition, vhash)
    a = FactoryBot.create(:answer, ahash)
    r = FactoryBot.create(:response, { answer: a, question: a.question }.merge(rhash))
    v.is_valid?(r)
  end

  it 'should validate a response by regexp' do
    expect(test_var({ operator: '=~', regexp: /^[a-z]{1,6}$/.to_s }, { response_class: 'string' }, string_value: 'clear')).to be_truthy
    expect(test_var({ operator: '=~', regexp: /^[a-z]{1,6}$/.to_s }, { response_class: 'string' }, string_value: 'foobarbaz')).to be_falsy
  end

  it 'should validate a response by integer comparison' do
    expect(test_var({ operator: '>', integer_value: 3 }, { response_class: 'integer' }, integer_value: 4)).to be_truthy
    expect(test_var({ operator: '<=', integer_value: 256 }, { response_class: 'integer' }, integer_value: 512)).to be_falsy
  end

  it 'should validate a response by (in)equality' do
    expect(test_var({ operator: '!=', datetime_value: Date.today + 1 }, { response_class: 'date' }, datetime_value: Date.today)).to be_truthy
    expect(test_var({ operator: '==', string_value: 'foo' }, { response_class: 'string' }, string_value: 'foo')).to be_truthy
  end

  it 'should represent itself as a hash' do
    validation_condition.rule_key = 'A'
    expect(validation_condition).to receive(:is_valid?) { true }
    expect(validation_condition.to_hash('foo')).to eq(A: true)
    expect(validation_condition).to receive(:is_valid?) { false }
    expect(validation_condition.to_hash('foo')).to eq(A: false)
  end

  # TODO: Change to shared examples
  def test_var2(v_hash, a_hash, r_hash, ca_hash, cr_hash)
    ca = FactoryBot.create(:answer, ca_hash)
    FactoryBot.create(:response, cr_hash.merge(answer: ca, question: ca.question))
    v = FactoryBot.create(:validation_condition, v_hash.merge(question_id: ca.question.id, answer_id: ca.id))
    a = FactoryBot.create(:answer, a_hash)
    r = FactoryBot.create(:response, r_hash.merge(answer: a, question: a.question))
    v.is_valid?(r)
  end

  it 'should validate a response by integer comparison' do
    expect(test_var2({ operator: '>' }, { response_class: 'integer' }, { integer_value: 4 }, { response_class: 'integer' }, integer_value: 3)).to be_truthy
    expect(test_var2({ operator: '<=' }, { response_class: 'integer' }, { integer_value: 512 }, { response_class: 'integer' }, integer_value: 4)).to be_falsy
  end

  it 'should validate a response by (in)equality' do
    expect(test_var2({ operator: '!=' }, { response_class: 'date' }, { datetime_value: Date.today }, { response_class: 'date' }, datetime_value: Date.today + 1)).to be_truthy
    expect(test_var2({ operator: '==' }, { response_class: 'string' }, { string_value: 'donuts' }, { response_class: 'string' }, string_value: 'donuts')).to be_truthy
  end

  it 'should not validate a response by regexp' do
    expect(test_var2({ operator: '=~' }, { response_class: 'date' }, { datetime_value: Date.today }, { response_class: 'date' }, datetime_value: Date.today + 1)).to be_falsy
    expect(test_var2({ operator: '=~' }, { response_class: 'string' }, { string_value: 'donuts' }, { response_class: 'string' }, string_value: 'donuts')).to be_falsy
  end
end
