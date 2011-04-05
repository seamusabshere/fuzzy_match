require 'delegate'
class LooseTightDictionary
  class Improver < ::Delegator
    class MissedChecks < RuntimeError; end

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
          log "  Mismatch! (should match SOMETHING)"
          raise Mismatch
        elsif right != correct_right
          log "  Mismatch! (#{right} should be #{correct_right})"
          raise Mismatch
        end
      end

      if negative_record = negatives.try(:detect) { |record| record[0] == left }
        incorrect_right = negative_record[1]
        if incorrect_right.blank? and right.present?
          log "  False positive! (should NOT match ANYTHING)"
          raise FalsePositive
        elsif right == incorrect_right
          log "  False positive! (#{right} should NOT be #{incorrect_right})"
          raise FalsePositive
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
          tee $ltd_1.map { |i| i.to_s.ljust(30) }.join if $ltd_1
        end
      end
    end
  end
end
