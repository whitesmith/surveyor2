module Surveyor
  module Models
    module ValidationMethods
      extend ActiveSupport::Concern

      include ActiveModel::Validations
      include ActiveModel::ForbiddenAttributesProtection
      include ActiveModel::MassAssignmentSecurity if defined?(::ProtectedAttributes)

      included do
        # Associations
        belongs_to :answer
        has_many :validation_conditions, dependent: :destroy
        
        if defined?(::ProtectedAttributes)
          attr_accessible(*PermittedParams.new.validation_attributes)
        end

        # Validations
        validates_presence_of :rule
        validates_format_of :rule, with: /\A(?<cond>((\s*!?[A-Z]+\s*)|(\s*!?\(\g<cond>\)\s*))(\s(and|or)\s\g<cond>)?)\Z/
      end

      # Instance Methods
      def is_valid?(response_set)
        ch = conditions_hash(response_set)
        rgx = Regexp.new(self.validation_conditions.map{|vc| ["a","o"].include?(vc.rule_key) ? "#{vc.rule_key}(?!nd|r)" : vc.rule_key}.join("|")) # exclude and, or
        # logger.debug "v: #{self.inspect}"
        # logger.debug "rule: #{self.rule.inspect}"
        # logger.debug "rexp: #{rgx.inspect}"
        # logger.debug "keyp: #{ch.inspect}"
        # logger.debug "subd: #{self.rule.gsub(rgx){|m| ch[m.to_sym]}}"
        eval(self.rule.gsub(rgx){|m| ch[m.to_sym]})
      end

      # A hash of the conditions (keyed by rule_key) and their evaluation (boolean) in the context of response_set
      def conditions_hash(response_set)
        hash = {}
        response = response_set.responses.detect{|r| r.answer_id.to_i == self.answer_id.to_i}
        # logger.debug "r: #{response.inspect}"
        self.validation_conditions.each{|vc| hash.merge!(vc.to_hash(response))}
        return hash
      end
    end
  end
end
