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

    def match(needle)
      record = super
      inline_check needle, record
      record
    end
    
    def inline_check(needle, record)
      return unless positives.present? or negatives.present?

      needle_value = read_needle needle
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
      log Result::TT::HEADERS.map { |i| i.ljust(30) }.join

      needles.each do |needle|
        match needle
      end
    end
    
    def explain(needle)
      match = match needle
      log "#" * 150
      log "# Match #{needle.inspect} => #{match.inspect}"
      log "#" * 150
      log
      log "Needle"
      log '(needle_reader proc not defined, so downcasing everything)' unless needle_reader
      log "-" * 150
      log read_needle(needle).inspect
      log
      log "Haystack"
      log '(haystack_reader proc not defined, so downcasing everything)' unless haystack_reader
      log "-" * 150
      log haystack.map { |record| read_haystack(record).inspect }.join("\n")
      log
      log "Tightenings"
      log "-" * 150
      log tightenings.empty? ? '(none)' : tightenings.map { |tightening| tightening.inspect }.join("\n")
      log
      log "Comparisons"
      log Result::TT::HEADERS.map { |i| i.ljust(50) }.join
      log '-' * 150
      log last_result.tts.uniq.sort.map { |tt| tt.inspect }.join("\n")
      log
      log "Match"
      log "-" * 150
      log match.inspect
    end
  end
end
