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

    def positives
      options[:positives]
    end

    def negatives
      options[:negatives]
    end

    def find(left_record)
      right_record = super
      inline_check left_record, right_record
      right_record
    end
    
    def inline_check(left_record, right_record)
      return unless positives.present? or negatives.present?

      left = read_left left_record
      right = read_right right_record

      if positive_record = positives.try(:detect) { |record| record[0] == left }
        correct_right = positive_record[1]
        if correct_right.present? and right.blank?
          raise FalseNegative, "#{left} should have matched #{correct_right}, but matched nothing"
        elsif right != correct_right
          raise Mismatch, "#{left} should have matched #{correct_right}, but matched #{right}"
        end
      end

      if negative_record = negatives.try(:detect) { |record| record[0] == left }
        incorrect_right = negative_record[1]
        if incorrect_right.blank? and right.present?
          raise FalsePositive, "#{left} shouldn't have matched anything, but it matched #{right}"
        elsif right == incorrect_right
          raise FalsePositive, "#{left} shouldn't have matched #{incorrect_right}, but it did!"
        end
      end
    end

    def check(left_records)
      header = [ 'Left record (input)', 'Right record (output)', 'Prefix used (if any)', 'Score' ]
      tee header.map { |i| i.to_s.ljust(30) }.join

      left_records.each do |left_record|
        begin
          right_record = find left_record
        ensure
          tee ::Thread.current[:ltd_last_run][right_record].map { |i| i.to_s.ljust(30) }.join if ::Thread.current[:ltd_last_run][right_record]
        end
      end
    end
  end
end
