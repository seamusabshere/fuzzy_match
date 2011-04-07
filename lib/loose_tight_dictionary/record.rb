require 'delegate'

class LooseTightDictionary
  class Record < ::Delegator
    class << self
      def wrap(orig_record, reader, tightenings)
        record = new orig_record
        record.instance_variable_set :@ltd_tightenings, tightenings
        record.instance_variable_set :@ltd_reader, reader
        record
      end
      
      def tighten(orig_record, reader, applied_tightening)
        record = new orig_record
        record.instance_variable_set :@ltd_reader, reader
        record.instance_variable_set :@ltd_applied_tightening, applied_tightening
        record
      end
    end

    # delegator interface

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

    # end delegator

    attr_reader :ltd_tightenings
    attr_reader :ltd_reader
    attr_reader :ltd_applied_tightening

    # methods i want to definitively override

    def to_str
      if ltd_applied_tightening
        ltd_tightened_value
      else
        ltd_read_value
      end
    end
    
    # def hash
    #   to_str.hash
    # end
    # 
    # def eql?(other)
    #   hash == other.hash
    # end
    
    # ... and those that i don't

    def ltd_read_value
      @ltd_read_value ||= ltd_reader ? ltd_reader.call(__getobj__) : __getobj__.to_s
    end

    def ltd_tightened_value
      @ltd_tightened_value ||= ltd_applied_tightening ? ltd_applied_tightening.apply(ltd_read_value) : ltd_read_value
    end

    def ltd_tightened?
      ltd_read_value != ltd_tightened_value
    end

    def ltd_interpretations
      raise RuntimeError, "interpretations should only be derived from non-tightened records" if ltd_applied_tightening
      ltd_tightenings.inject([ self ]) do |memo, tightening|
        if tightening.apply? ltd_read_value
          memo.push Record.tighten(__getobj__, ltd_reader, tightening)
        end
        memo
      end.uniq
    end
    
    def ltd_score(other)
      # if prefixed...
      to_str.pair_distance_similar other.to_str
    end
  end
end
