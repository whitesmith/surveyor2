# encoding: UTF-8
class Surveyor::Survey < ActiveRecord::Base; end
class Surveyor::Question < ActiveRecord::Base; end
class Surveyor::QuestionGroup < ActiveRecord::Base; end
class Surveyor::Answer < ActiveRecord::Base; end
class Surveyor::Response < ActiveRecord::Base; end
class Surveyor::ResponseSet < ActiveRecord::Base; end

class UpdateBlankApiIdsOnQuestionGroup < ActiveRecord::Migration[5.0]
  def self.up
    check = [Surveyor::Survey, Surveyor::Question, Surveyor::QuestionGroup, Surveyor::Answer, Surveyor::Response, Surveyor::ResponseSet]
    check.each do |clazz|
      clazz.where('api_id IS ?', nil).each do |c|
        c.api_id = Surveyor::Common.generate_api_id
        c.save!
      end
    end
  end

  def self.down
  end
end
