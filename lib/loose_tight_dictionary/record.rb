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

    def ltd_unwrap
      __getobj__
    end

    attr_reader :ltd_tightenings
    attr_reader :ltd_reader
    attr_reader :ltd_applied_tightening

    def ltd_to_str
      if ltd_applied_tightening
        ltd_tightened_value
      else
        ltd_read_value
      end
    end
        
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
    
    def ltd_optimal_prefix_range(other)
      if ltd_tightened? and other.ltd_tightened?
        0..([ ltd_to_str.length, other.ltd_to_str.length ].min-1)
      end
    end
    
    def ltd_score(other)
      if optimal_prefix_range = ltd_optimal_prefix_range(other)
        ltd_to_str[optimal_prefix_range].pair_distance_similar other.ltd_to_str[optimal_prefix_range]
      else
        ltd_to_str.pair_distance_similar other.ltd_to_str
      end
    end
  end
end
