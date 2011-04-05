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
      haystack_record = super
      inline_check needle_record, haystack_record
      haystack_record
    end
    
    def inline_check(needle_record, haystack_record)
      return unless positives.present? or negatives.present?

      needle = read_needle needle_record
      haystack = read_haystack haystack_record

      if positive_record = positives.try(:detect) { |record| record[0] == needle }
        correct_haystack = positive_record[1]
        if correct_haystack.present? and haystack.blank?
          raise FalseNegative, "#{needle} should have matched #{correct_haystack}, but matched nothing"
        elsif haystack != correct_haystack
          raise Mismatch, "#{needle} should have matched #{correct_haystack}, but matched #{haystack}"
        end
      end

      if negative_record = negatives.try(:detect) { |record| record[0] == needle }
        incorrect_haystack = negative_record[1]
        if incorrect_haystack.blank? and haystack.present?
          raise FalsePositive, "#{needle} shouldn't have matched anything, but it matched #{haystack}"
        elsif haystack == incorrect_haystack
          raise FalsePositive, "#{needle} shouldn't have matched #{incorrect_haystack}, but it did!"
        end
      end
    end

    def check(needle_records)
      log Result::Record::HEADERS.map { |i| i.ljust(30) }.join

      needle_records.each do |needle_record|
        haystack_record = match needle_record
        log last_result.records.map { |_, r| r.to_s.ljust(30) }.join("\n")
        log
      end
    end
  end
end
