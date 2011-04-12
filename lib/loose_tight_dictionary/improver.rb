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
    
    def __getobj__ #:nodoc:
      @_ch_obj
    end
    
    def __setobj__(obj) #:nodoc:
      @_ch_obj = obj
    end

    def log(str = '') #:nodoc:
      (options[:log] || $stderr).puts str unless options[:log] == false
    end
  
    def positives #:nodoc:
      options[:positives]
    end

    def negatives #:nodoc:
      options[:negatives]
    end

    # When you find from an improver, it checks the results against the known positives/negatives.
    #
    #     d.improver.find('737')
    def find(needle)
      record = super
      inline_check needle, record
      record
    end
    
    def inline_check(needle, record) #:nodoc
      return unless positives.present? or negatives.present?

      needle = Scorable.new :parent => self, :record => needle, :reader => needle_reader
      record = Scorable.new :parent => self, :record => record, :reader => haystack_reader

      if positive_record = positives.try(:detect) { |record| record[0] == needle }
        correct_record = positive_record[1]
        if correct_record.present? and record.blank?
          raise FalseNegative, "#{needle} should have matched #{correct_record}, but matched nothing"
        elsif record != correct_record
          raise Mismatch, "#{needle} should have matched #{correct_record}, but matched #{record}"
        end
      end

      if negative_record = negatives.try(:detect) { |record| record[0] == needle }
        incorrect_record = negative_record[1]
        if incorrect_record.blank? and record.present?
          raise FalsePositive, "#{needle} shouldn't have matched anything, but it matched #{record}"
        elsif record == incorrect_record
          raise FalsePositive, "#{needle} shouldn't have matched #{incorrect_record}, but it did!"
        end
      end
    end

    # Give check a list of needles that you want to find and it will help you improve your dictionary.
    #
    #     d = LooseTightDictionary.new ['737', '747', '757' ]
    #     d.improver.check [ 'boeing 737-100', '747sp', 'mcdonnell douglas dc-9' ]
    def check(needles)
      skipped = []
      needles.each do |needle|
        begin
          if record = find(needle)
            log
            log "%0.2f" % last_result.score
            log(needle_reader ? needle_reader.call(needle) : needle)
            log(haystack_reader ? haystack_reader.call(record) : record)
          else
            skipped << needle
          end
        rescue
          log
          log $!.inspect
        end
      end
      
      log
      log 'skipped'
      log
      
      skipped.each do |needle|
        log (needle_reader ? needle_reader.call(needle) : needle)
      end
    end

    # Explain is like mysql's EXPLAIN command. You give it a needle and it tells you about how it was located (successfully or not) in the haystack.
    #
    #     d = LooseTightDictionary.new ['737', '747', '757' ]
    #     d.improver.explain 'boeing 737-100'
    def explain(needle)
      record = find needle
      log "#" * 150
      log "# Match #{needle.inspect} => #{record.inspect}"
      log "#" * 150
      log
      log "Needle"
      log "-" * 150
      log last_result.needle.to_str
      log
      log "Haystack"
      log "-" * 150
      log last_result.haystack.map { |record| record.to_str }.join("\n")
      log
      log "Tightenings"
      log "-" * 150
      log last_result.tightenings.blank? ? '(none)' : last_result.tightenings.map { |tightening| tightening.inspect }.join("\n")
      log
      log "Blockings"
      log "-" * 150
      log last_result.blockings.blank? ? '(none)' : last_result.blockings.map { |blocking| blocking.inspect }.join("\n")
      log
      log "Identities"
      log "-" * 150
      log last_result.identities.blank? ? '(none)' : last_result.identities.map { |blocking| blocking.inspect }.join("\n")
      log
      log "Comparison allowed"
      log "-" * 150
      log last_result.encompassed.blank? ? '(none)' : last_result.encompassed.map { |encompassed| encompassed.to_str }.join("\n")
      log
      log "Comparison disallowed"
      log "-" * 150
      log last_result.unencompassed.blank? ? '(none)' : last_result.unencompassed.map { |unencompassed| unencompassed.to_str }.join("\n")
      log
      log "Scorables"
      log "-" * 150
      log last_result.scores.blank? ? '(none)' : last_result.scores.sort_by { |k, v| v }.reverse.map { |k, v| "#{k.to_str} - #{v}" }.join("\n")
      log
      log "Match"
      log "-" * 150
      log record.inspect
    end
  end
end
