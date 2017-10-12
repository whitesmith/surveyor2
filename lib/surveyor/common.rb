require 'uuidtools'

module Surveyor
  class Common
    OPERATORS = %w(== != < > <= >= =~)

    def self.make_tiny_code
      SecureRandom.urlsafe_base64(7)
    end

    def self.normalize_string(text)
      words_to_omit = %w(a be but has have in is it of on or the to when)
      col_text = text.to_s.gsub(/(<[^>]*>)|\n|\t/su, ' ') # Remove html tags
      col_text.downcase!                            # Remove capitalization
      col_text.gsub!(/\"|\'/u, '')                   # Remove potential problem characters
      col_text.gsub!(/\(.*?\)/u,'')                  # Remove text inside parens
      col_text.gsub!(/\W/u, ' ')                     # Remove all other non-word characters
      cols = (col_text.split(' ') - words_to_omit)
      (cols.size > 5 ? cols[-5..-1] : cols).join("_")
    end

    def self.generate_api_id
      UUIDTools::UUID.random_create.to_s
    end
  end
end
