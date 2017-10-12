require 'spec_helper'

describe Surveyor::ResponseSet, type: :model do
  subject(:response_set) { FactoryGirl.create(:response_set) }

  it { should be_valid }
  it { should belong_to(:survey) }
  # TODO: user comes from application, an idea might be to create a fake user class
  # it { should belong_to(:user) }
  it { should have_many(:responses).dependent(:destroy) }
  it { should validate_presence_of(:survey_id) }
  it { should validate_presence_of(:access_code) }
  it { should validate_presence_of(:started_at) }
  it { should validate_presence_of(:api_id) }
  it { should validate_uniqueness_of(:access_code) }

  context 'access_code' do
    it 'should have length 10' do
      expect(response_set.access_code.length).to eq(10)
    end

    # Regression test for #263
    it 'should be accepted in constructor' do
      response_set = FactoryGirl.build(:response_set)
      response_set.access_code = 'foo'
      expect(response_set.save).to be_truthy
      response_set.reload
      expect(response_set.access_code).to eq('foo')
    end

    it 'should be set on create if nil' do
      response_set = FactoryGirl.build(:response_set)
      response_set.access_code = nil
      expect(response_set.save).to be_truthy
      response_set.reload
      expect(response_set.access_code).not_to be_nil
    end
  end

  it 'should completable' do
    expect(response_set.completed_at).to be_nil
    expect(response_set).not_to be_complete
    response_set.complete!
    expect(response_set.completed_at).not_to be_nil
    expect(response_set.completed_at.is_a?(Time)).to be_truthy
    expect(response_set).to be_complete
  end

  it 'saves its responses' do
    question = FactoryGirl.create(:question)
    answer = FactoryGirl.create(:answer, question: question)

    response_set.responses.build(question_id: question.id, answer_id: answer.id, string_value: 'foo')
    expect(response_set.save).to be_truthy
    response_set.reload

    expect(response_set.responses.length).to eq(1)
  end

  context '#update_from_ui_hash' do
    let(:ui_hash) { {} }
    let(:api_id)  { 'ABCDEF-1234-567890' }

    let(:question) { FactoryGirl.create(:question) }
    let(:answer) { FactoryGirl.create(:answer, question: question) }

    def ui_response(attrs = {})
      { 'question_id' => question.id.to_s, 'api_id' => api_id }.merge(attrs)
    end

    def do_ui_update
      response_set.update_from_ui_hash(ui_hash)
    end

    def resulting_response
      # response_set_id criterion is to make sure a created response is
      # appropriately associated.
      Surveyor::Response.where(api_id: api_id, response_set_id: response_set.id).first
    end

    shared_examples 'pick one or any' do
      it 'saves an answer alone' do
        ui_hash['3'] = ui_response('answer_id' => set_answer_id)
        do_ui_update
        expect(resulting_response.answer_id).to eq(answer.id)
      end

      it 'preserves the question' do
        ui_hash['4'] = ui_response('answer_id' => set_answer_id)
        do_ui_update
        expect(resulting_response.question_id).to eq(question.id)
      end

      it 'interprets a blank answer as no response' do
        ui_hash['7'] = ui_response('answer_id' => blank_answer_id)
        do_ui_update
        expect(resulting_response).to be_nil
      end

      it 'interprets no answer_id as no response' do
        ui_hash['8'] = ui_response
        do_ui_update
        expect(resulting_response).to be_nil
      end

      [
        ['string_value',   'foo',              '', 'foo'],
        ['datetime_value', '2010-10-01 17:15', '', Time.zone.parse('2010-10-1 17:15')],
        ['date_value',     '2010-10-01',       '', '2010-10-01'],
        ['time_value',     '17:15',            '', '17:15'],
        ['integer_value',  '9',                '', 9],
        ['float_value',    '4.0',              '', 4.0],
        ['text_value',     'more than foo',    '', 'more than foo']
      ].each do |value_type, set_value, blank_value, expected_value|
        describe "plus #{value_type}" do
          it 'saves the value' do
            ui_hash['11'] = ui_response('answer_id' => set_answer_id, value_type => set_value)
            do_ui_update
            expect(resulting_response.send(value_type)).to eq(expected_value)
          end

          it 'interprets a blank answer as no response' do
            ui_hash['18'] = ui_response('answer_id' => blank_answer_id, value_type => set_value)
            do_ui_update
            expect(resulting_response).to be_nil
          end

          it 'interprets a blank value as no response' do
            ui_hash['29'] = ui_response('answer_id' => set_answer_id, value_type => blank_value)
            do_ui_update
            expect(resulting_response).to be_nil
          end

          it 'interprets no answer_id as no response' do
            ui_hash['8'] = ui_response(value_type => set_value)
            do_ui_update
            expect(resulting_response).to be_nil
          end
        end
      end
    end

    shared_examples 'response interpretation' do
      it 'fails when api_id is not provided' do
        ui_hash['0'] = { 'question_id' => question.id }
        expect { do_ui_update }.to raise_error(/api_id missing from response 0/)
      end

      describe 'for a radio button' do
        let(:set_answer_id)   { answer.id.to_s }
        let(:blank_answer_id) { '' }

        include_examples 'pick one or any'
      end

      describe 'for a checkbox' do
        let(:set_answer_id)   { ['', answer.id.to_s] }
        let(:blank_answer_id) { [''] }

        include_examples 'pick one or any'
      end
    end

    describe 'with a new response' do
      include_examples 'response interpretation'

      # After much effort I cannot produce this situation in a test, either with
      # with threads or separate processes. While SQLite 3 will nominally allow
      # for some coarse-grained concurrency, it does not appear to work with
      # simultaneous write transactions the way AR uses SQLite. Instead,
      # simultaneous write transactions always result in a
      # SQLite3::BusyException, regardless of the connection's timeout setting.
      it 'fails predicably when another response with the same api_id is created in a simultaneous open transaction'
    end

    describe 'with an existing response' do
      let!(:original_response) do
        response_set.responses.build(question_id: question.id, answer_id: answer.id).tap do |r|
          r.api_id = api_id # not mass assignable
          r.save!
        end
      end

      include_examples 'response interpretation'

      it 'fails when the existing response is for a different question' do
        ui_hash['76'] = ui_response('question_id' => '43', 'answer_id' => answer.id.to_s)

        expect { do_ui_update }.to raise_error(/Illegal attempt to change question for response #{api_id}./)
      end
    end

    # clean_with_truncation is necessary because AR 3.0 can't roll back a nested
    # transaction with SQLite.
    it 'rolls back all changes on failure', :clean_with_truncation do
      ui_hash['0'] = ui_response('question_id' => '42', 'answer_id' => answer.id.to_s)
      ui_hash['1'] = { 'answer_id' => '7' } # no api_id

      expect { do_ui_update }.to raise_error(/api_id missing from response [0-9]+/)

      expect(response_set.reload.responses).to be_empty
    end
  end

  describe 'with dependencies' do
    let!(:section) { FactoryGirl.create(:survey_section) }
    # Questions
    let!(:do_you_like_pie) { FactoryGirl.create(:question, text: 'Do you like pie?', survey_section: section) }
    let!(:what_flavor) { FactoryGirl.create(:question, text: 'What flavor?', survey_section: section) }
    let!(:what_bakery) { FactoryGirl.create(:question, text: 'What bakery?', survey_section: section) }
    # Answers
    let!(:do_you_like_pie_answer_yes) { FactoryGirl.create(:answer, text: 'yes', question_id: do_you_like_pie.id) }
    let!(:do_you_like_pie_answer_no) { FactoryGirl.create(:answer, text: 'no', question_id: do_you_like_pie.id) }
    let!(:what_flavor_answer) { FactoryGirl.create(:answer, response_class: :string, question_id: what_flavor.id) }
    let!(:what_bakery_answer) { FactoryGirl.create(:answer, response_class: :string, question_id: what_bakery.id) }
    # Dependency
    let!(:what_flavor_dep) { FactoryGirl.create(:dependency, rule: 'A', question_id: what_flavor.id) }
    let!(:what_flavor_dep_cond) { FactoryGirl.create(:dependency_condition, rule_key: 'A', question_id: do_you_like_pie.id, operator: '==', answer_id: do_you_like_pie_answer_yes.id, dependency_id: what_flavor_dep.id) }
    let!(:what_bakery_dep) { FactoryGirl.create(:dependency, rule: 'B', question_id: what_bakery.id) }
    let!(:what_bakery_dep_cond) { FactoryGirl.create(:dependency_condition, rule_key: 'B', question_id: do_you_like_pie.id, operator: '==', answer_id: do_you_like_pie_answer_yes.id, dependency_id: what_bakery_dep.id) }
    # Responses
    subject(:response_set) { FactoryGirl.create(:response_set) }
    let!(:response_1) { FactoryGirl.create(:response, question_id: do_you_like_pie.id, answer_id: do_you_like_pie_answer_yes.id, response_set_id: response_set.id) }
    let!(:response_2) { FactoryGirl.create(:response, string_value: 'pecan pie', question_id: what_flavor.id, answer_id: what_flavor_answer.id, response_set_id: response_set.id) }

    before(:each) do
      response_set.reload
    end

    it 'should list unanswered dependencies to show at the top of the next page (javascript turned off)' do
      expect(response_set.unanswered_dependencies).to eq([what_bakery])
    end

    it 'should list answered and unanswered dependencies to show inline (javascript turned on)' do
      expect(response_set.reload.all_dependencies[:show]).to eq(["q_#{what_flavor.id}", "q_#{what_bakery.id}"])
    end

    it 'should list group as dependency' do
      # Question Group
      crust_group = FactoryGirl.create(:question_group, text: 'Favorite Crusts')

      # Question
      what_crust = FactoryGirl.create(:question, text: 'What is your favorite curst type?', survey_section: section)
      crust_group.questions << what_crust

      # Answers
      what_crust.answers << FactoryGirl.create(:answer, response_class: :string, question_id: what_crust.id)

      # Dependency
      crust_group_dep = FactoryGirl.create(:dependency, rule: 'C', question_group_id: crust_group.id, question: nil)
      FactoryGirl.create(:dependency_condition, rule_key: 'C', question_id: do_you_like_pie.id, operator: '==', answer_id: do_you_like_pie_answer_yes.id, dependency_id: crust_group_dep.id)

      expect(response_set.unanswered_dependencies).to eq([what_bakery, crust_group])
    end
  end

  describe 'dependency_conditions' do
    let!(:section) { FactoryGirl.create(:survey_section) }
    # Questions
    let!(:like_pie) { FactoryGirl.create(:question, text: 'Do you like pie?', survey_section: section) }
    let!(:like_jam) { FactoryGirl.create(:question, text: 'Do you like jam?', survey_section: section) }
    let!(:what_is_wrong_with_you) { FactoryGirl.create(:question, text: "What's wrong with you?", survey_section: section) }
    # Answers
    let!(:like_pie_yes) { FactoryGirl.create(:answer, text: 'yes', question_id: like_pie.id) }
    let!(:like_pie_no) { FactoryGirl.create(:answer, text: 'no', question_id: like_pie.id) }
    let!(:like_jam_yes) { FactoryGirl.create(:answer, text: 'yes', question_id: like_jam.id) }
    let!(:like_jam_no) { FactoryGirl.create(:answer, text: 'no', question_id: like_jam.id) }
    # Dependency
    let!(:what_is_wrong_with_you_dep) { FactoryGirl.create(:dependency, rule: 'A or B', question_id: what_is_wrong_with_you.id) }
    let!(:dep_a) { FactoryGirl.create(:dependency_condition, rule_key: 'A', question_id: like_pie.id, operator: '==', answer_id: like_pie_yes.id, dependency_id: what_is_wrong_with_you_dep.id) }
    let!(:dep_b) { FactoryGirl.create(:dependency_condition, rule_key: 'B', question_id: like_jam.id, operator: '==', answer_id: like_jam_yes.id, dependency_id: what_is_wrong_with_you_dep.id) }
    # Responses
    subject(:response_set) { FactoryGirl.create(:response_set) }
    let!(:response) { FactoryGirl.create(:response, question_id: like_pie.id, answer_id: like_pie_yes.id, response_set_id: response_set.id) }

    before(:each) do
      response_set.reload
    end

    it 'should list all dependencies for answered questions' do
      dependency_conditions = response_set.send(:dependencies).last.dependency_conditions
      expect(dependency_conditions.size).to eq(2)
      expect(dependency_conditions).to include(dep_a)
      expect(dependency_conditions).to include(dep_b)
    end

    it 'should list all dependencies for passed question_id' do
      # Questions
      like_ice_cream = FactoryGirl.create(:question, text: 'Do you like ice_cream?', survey_section: section)
      what_flavor = FactoryGirl.create(:question, text: 'What flavor?', survey_section: section)
      # Answers
      like_ice_cream.answers << FactoryGirl.create(:answer, text: 'yes', question_id: like_ice_cream.id)
      like_ice_cream.answers << FactoryGirl.create(:answer, text: 'no', question_id: like_ice_cream.id)
      what_flavor.answers << FactoryGirl.create(:answer, response_class: :string, question_id: what_flavor.id)
      # Dependency
      flavor_dependency = FactoryGirl.create(:dependency, rule: 'C', question_id: what_flavor.id)
      FactoryGirl.create(:dependency_condition, rule_key: 'A', question_id: like_ice_cream.id, operator: '==', answer_id: like_ice_cream.answers.first.id, dependency_id: flavor_dependency.id)
      # Responses
      expect(response_set.send(:dependencies, like_ice_cream.id)).to eq([flavor_dependency])
    end
  end

  describe 'as a quiz' do
    let(:survey) { FactoryGirl.create(:survey) }
    let(:section) { FactoryGirl.create(:survey_section, survey: survey) }
    subject(:response_set) { FactoryGirl.create(:response_set, survey: survey) }

    def generate_responses(count, quiz = nil, correct = nil)
      count.times do |_i|
        q = FactoryGirl.create(:question, survey_section: section)
        a = FactoryGirl.create(:answer, question: q, response_class: 'answer')
        x = FactoryGirl.create(:answer, question: q, response_class: 'answer')
        q.correct_answer = (quiz == 'quiz' ? a : nil)
        response_set.responses << FactoryGirl.create(:response, question: q, answer: (correct == 'correct' ? a : x))
      end
    end

    it 'should report correctness if it is a quiz' do
      generate_responses(3, 'quiz', 'correct')
      expect(response_set.correct?).to eq(true)
      expect(response_set.correctness_hash).to eq(questions: 3, responses: 3, correct: 3)
    end

    it 'should report incorrectness if it is a quiz' do
      generate_responses(3, 'quiz', 'incorrect')
      expect(response_set.correct?).to eq(false)
      expect(response_set.correctness_hash).to eq(questions: 3, responses: 3, correct: 0)
    end

    it "should report correct if it isn't a quiz" do
      generate_responses(3, 'non-quiz')
      expect(response_set.correct?).to eq(true)
      expect(response_set.correctness_hash).to eq(questions: 3, responses: 3, correct: 3)
    end
  end

  describe 'with mandatory questions' do
    let(:survey) { FactoryGirl.create(:survey) }
    let(:section) { FactoryGirl.create(:survey_section, survey: survey) }
    subject(:response_set) { FactoryGirl.create(:response_set, survey: survey) }

    def generate_responses(count, mandatory = nil, responded = nil)
      count.times do |_i|
        q = FactoryGirl.create(:question, survey_section: section, is_mandatory: (mandatory == 'mandatory'))
        a = FactoryGirl.create(:answer, question: q, response_class: 'answer')
        if responded == 'responded'
          response_set.responses << FactoryGirl.create(:response, question: q, answer: a)
        end
      end
    end

    it 'should report progress without mandatory questions' do
      generate_responses(3)
      expect(response_set.mandatory_questions_complete?).to eq(true)
      expect(response_set.progress_hash).to eq(questions: 3, triggered: 3, triggered_mandatory: 0, triggered_mandatory_completed: 0)
    end

    it 'should report progress with mandatory questions' do
      generate_responses(3, 'mandatory', 'responded')
      expect(response_set.mandatory_questions_complete?).to eq(true)
      expect(response_set.progress_hash).to eq(questions: 3, triggered: 3, triggered_mandatory: 3, triggered_mandatory_completed: 3)
    end

    it 'should report progress with mandatory questions' do
      generate_responses(3, 'mandatory', 'not-responded')
      expect(response_set.mandatory_questions_complete?).to eq(false)
      expect(response_set.progress_hash).to eq(questions: 3, triggered: 3, triggered_mandatory: 3, triggered_mandatory_completed: 0)
    end

    it 'should ignore labels and images' do
      generate_responses(3, 'mandatory', 'responded')
      FactoryGirl.create(:question, survey_section: section, display_type: 'label', is_mandatory: true)
      FactoryGirl.create(:question, survey_section: section, display_type: 'image', is_mandatory: true)
      expect(response_set.mandatory_questions_complete?).to eq(true)
      expect(response_set.progress_hash).to eq(questions: 5, triggered: 5, triggered_mandatory: 5, triggered_mandatory_completed: 5)
    end
  end

  describe 'with mandatory, dependent questions' do
    let(:survey) { FactoryGirl.create(:survey) }
    let(:section) { FactoryGirl.create(:survey_section, survey: survey) }
    subject(:response_set) { FactoryGirl.create(:response_set, survey: survey) }

    def generate_responses(count, mandatory = nil, dependent = nil, triggered = nil)
      dq = FactoryGirl.create(:question, survey_section: section, is_mandatory: (mandatory == 'mandatory'))
      da = FactoryGirl.create(:answer, question: dq, response_class: 'answer')
      dx = FactoryGirl.create(:answer, question: dq, response_class: 'answer')
      count.times do |_i|
        q = FactoryGirl.create(:question, survey_section: section, is_mandatory: (mandatory == 'mandatory'))
        a = FactoryGirl.create(:answer, question: q, response_class: 'answer')
        if dependent == 'dependent'
          d = FactoryGirl.create(:dependency, question: q)
          FactoryGirl.create(:dependency_condition, dependency: d, question_id: dq.id, answer_id: da.id)
        end
        response_set.responses << FactoryGirl.create(:response, response_set: response_set, question: dq, answer: (triggered == 'triggered' ? da : dx))
        response_set.responses << FactoryGirl.create(:response, response_set: response_set, question: q, answer: a)
      end
    end

    it 'should report progress without mandatory questions' do
      generate_responses(3, 'mandatory', 'dependent')
      expect(response_set.mandatory_questions_complete?).to eq(true)
      expect(response_set.progress_hash).to eq(questions: 4, triggered: 1, triggered_mandatory: 1, triggered_mandatory_completed: 1)
    end

    it 'should report progress with mandatory questions' do
      generate_responses(3, 'mandatory', 'dependent', 'triggered')
      expect(response_set.mandatory_questions_complete?).to eq(true)
      expect(response_set.progress_hash).to eq(questions: 4, triggered: 4, triggered_mandatory: 4, triggered_mandatory_completed: 4)
    end
  end

  describe 'exporting csv' do
    let!(:section) { FactoryGirl.create(:survey_section) }
    # Questions
    let!(:do_you_like_pie) { FactoryGirl.create(:question, text: 'Do you like pie?', survey_section: section) }
    let!(:what_flavor) { FactoryGirl.create(:question, text: 'What flavor?', survey_section: section) }
    let!(:what_bakery) { FactoryGirl.create(:question, text: 'What bakery?', survey_section: section) }
    # Answers
    let!(:do_you_like_pie_answer_yes) { FactoryGirl.create(:answer, text: 'yes', question_id: do_you_like_pie.id) }
    let!(:do_you_like_pie_answer_no) { FactoryGirl.create(:answer, text: 'no', question_id: do_you_like_pie.id) }
    let!(:what_flavor_answer) { FactoryGirl.create(:answer, response_class: :string, question_id: what_flavor.id) }
    let!(:what_bakery_answer) { FactoryGirl.create(:answer, response_class: :string, question_id: what_bakery.id) }
    # Dependency
    let!(:what_flavor_dep) { FactoryGirl.create(:dependency, rule: 'A', question_id: what_flavor.id) }
    let!(:what_flavor_dep_cond) { FactoryGirl.create(:dependency_condition, rule_key: 'A', question_id: do_you_like_pie.id, operator: '==', answer_id: do_you_like_pie_answer_yes.id, dependency_id: what_flavor_dep.id) }
    let!(:what_bakery_dep) { FactoryGirl.create(:dependency, rule: 'B', question_id: what_bakery.id) }
    let!(:what_bakery_dep_cond) { FactoryGirl.create(:dependency_condition, rule_key: 'B', question_id: do_you_like_pie.id, operator: '==', answer_id: do_you_like_pie_answer_yes.id, dependency_id: what_bakery_dep.id) }
    # Responses
    subject(:response_set) { FactoryGirl.create(:response_set) }
    let!(:response_1) { FactoryGirl.create(:response, question_id: do_you_like_pie.id, answer_id: do_you_like_pie_answer_yes.id, response_set_id: response_set.id) }
    let!(:response_2) { FactoryGirl.create(:response, string_value: 'pecan pie', question_id: what_flavor.id, answer_id: what_flavor_answer.id, response_set_id: response_set.id) }

    before(:each) do
      response_set.reload
    end

    it 'should export a string with responses' do
      expect(response_set.responses.size).to eq(2)
      csv = response_set.to_csv
      expect(csv.is_a?(String)).to eq(true)
      expect(csv).to match('question.short_text')
      expect(csv).to match('What flavor?')
      expect(csv).to match(/pecan pie/)
    end
  end

  describe '#as_json' do
    let(:response_set) do
      FactoryGirl.create(:response_set, responses: [
                           FactoryGirl.create(:response, question: FactoryGirl.create(:question), answer: FactoryGirl.create(:answer), string_value: '2')
                         ])
    end

    subject(:js) { response_set.as_json }

    it 'should include uuid, survey_id' do
      expect(js[:uuid]).to eq(response_set.api_id)
    end

    it 'should include responses with uuid, question_id, answer_id, value' do
      r0 = response_set.responses[0]
      expect(js[:responses][0][:uuid]).to eq(r0.api_id)
      expect(js[:responses][0][:answer_id]).to eq(r0.answer.api_id)
      expect(js[:responses][0][:question_id]).to eq(r0.question.api_id)
      expect(js[:responses][0][:value]).to eq(r0.string_value)
    end
  end
end
