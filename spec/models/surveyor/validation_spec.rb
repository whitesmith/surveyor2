require 'spec_helper'

describe Surveyor::Validation, type: :model do
  subject(:validation) { FactoryBot.create(:validation) }

  it { should be_valid }
  it { should validate_presence_of(:rule) }
  it { should allow_values('A', 'B', 'A and B', 'A or B', '!A', '!(A)', '(A and B)', '(A and B or C) or (D and (B or C))', '(((A and B) or C) or D) and E').for(:rule) }
  it { should_not allow_values('', 'foo', '1 to 2', 'a and b', '(A', 'A)', 'A!', 'A)!', 'A (A and B)', '(A) B', '(A) (B)').for(:rule) }

  # this causes issues with building and saving
  # it "should be invalid without a answer_id" do
  #   @validation.answer_id = nil
  #   @validation.should have(1).error_on(:answer_id)
  # end

  # TODO: improve to shared_examples
  context 'reporting its status' do
    def test_var(vhash, vchashes, ahash, rhash)
      a = FactoryBot.create(:answer, ahash)
      v = FactoryBot.create(:validation, { answer: a, rule: 'A' }.merge(vhash))
      vchashes.each do |vchash|
        FactoryBot.create(:validation_condition, { validation: v, rule_key: 'A' }.merge(vchash))
      end
      rs = FactoryBot.create(:response_set)
      r = FactoryBot.create(:response, { answer: a, question: a.question }.merge(rhash))
      rs.responses << r
      v.is_valid?(rs)
    end

    it 'should validate a response by integer comparison' do
      expect(test_var({ rule: 'A and B' }, [{ operator: '>=', integer_value: 0 }, { rule_key: 'B', operator: '<=', integer_value: 120 }], { response_class: 'integer' }, integer_value: 48)).to be_truthy
    end

    it 'should validate a response by regexp' do
      expect(test_var({}, [{ operator: '=~', regexp: '/^[a-z]{1,6}$/' }], { response_class: 'string' }, string_value: '')).to be_falsy
    end
  end

  context 'with conditions' do
    it 'should destroy conditions when destroyed' do
      validation = FactoryBot.create(:validation)
      FactoryBot.create(:validation_condition, validation: @validation, rule_key: 'A')
      FactoryBot.create(:validation_condition, validation: @validation, rule_key: 'B')
      FactoryBot.create(:validation_condition, validation: @validation, rule_key: 'C')
      v_ids = validation.validation_conditions.map(&:id)
      validation.destroy
      v_ids.each { |_id| expect(Surveyor::DependencyCondition).to be_nil }
    end
  end
end
