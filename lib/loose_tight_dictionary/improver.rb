require 'delegate'
class LooseTightDictionary
  class Improver < ::Delegator
    class MissedChecks < RuntimeError; end
    class Mismatch < RuntimeError; end
    class FalseNegative < RuntimeError; end
    class FalsePositive < RuntimeError; end

    def initialize(obj)
      super
      @_ch_obj = obj
    end
    
    def __getobj__
      @_ch_obj
    end
    
    def __setobj__(obj)
      @_ch_obj = obj
    end

    def log(str = '')
      (options[:log] || $stderr).puts str unless options[:log] == false
    end
  
    def positives
      options[:positives]
    end

    def negatives
      options[:negatives]
    end

    def match(needle_record)
      record = super
      inline_check needle_record, record
      record
    end
    
    def inline_check(needle_record, record)
      return unless positives.present? or negatives.present?

      needle_value = read_needle needle_record
      value = read_haystack record

      if positive_record = positives.try(:detect) { |record| record[0] == needle_value }
        correct_value = positive_record[1]
        if correct_value.present? and value.blank?
          raise FalseNegative, "#{needle_value} should have matched #{correct_value}, but matched nothing"
        elsif value != correct_value
          raise Mismatch, "#{needle_value} should have matched #{correct_value}, but matched #{value}"
        end
      end

      if negative_record = negatives.try(:detect) { |record| record[0] == needle_value }
        incorrect_value = negative_record[1]
        if incorrect_value.blank? and value.present?
          raise FalsePositive, "#{needle_value} shouldn't have matched anything, but it matched #{value}"
        elsif value == incorrect_value
          raise FalsePositive, "#{needle_value} shouldn't have matched #{incorrect_value}, but it did!"
        end
      end
    end

    def check(needles)
      log Result::Record::HEADERS.map { |i| i.ljust(30) }.join

      needles.each do |needle_record|
        record = match needle_record
        log last_result.records.map { |_, r| r.to_s.ljust(30) }.join("\n")
        log
      end
    end
  end
end
