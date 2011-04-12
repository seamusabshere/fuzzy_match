require 'active_support'
require 'active_support/version'
%w{
  active_support/core_ext/string
  active_support/core_ext/hash
  active_support/core_ext/object
}.each do |active_support_3_requirement|
  require active_support_3_requirement
end if ::ActiveSupport::VERSION::MAJOR == 3

# See the README for more information.
class LooseTightDictionary
  autoload :ExtractRegexp, 'loose_tight_dictionary/extract_regexp'
  autoload :Tightener, 'loose_tight_dictionary/tightener'
  autoload :Tightening, 'loose_tight_dictionary/tightening'
  autoload :Blocking, 'loose_tight_dictionary/blocking'
  autoload :Identity, 'loose_tight_dictionary/identity'
  autoload :Result, 'loose_tight_dictionary/result'
  autoload :Wrapper, 'loose_tight_dictionary/wrapper'
  autoload :Similarity, 'loose_tight_dictionary/similarity'
  autoload :Improver, 'loose_tight_dictionary/improver'
  
  class Freed < RuntimeError; end
  
  attr_reader :options
  attr_reader :haystack
  attr_reader :records

  # haystack - a bunch of records
  # options
  # * tighteners: regexps that essentialize strings down
  # * identities: regexps that rule out similarities, for example a 737 cannot be identical to a 747
  def initialize(records, options = {})
    @options = options.symbolize_keys
    @records = records
    @haystack = records.map { |record| Wrapper.new :parent => self, :record => record, :reader => haystack_reader }
  end
  
  def improver
    @improver ||= Improver.new self
  end
  
  def last_result
    @last_result ||= Result.new
  end
  
  def find_with_score(needle)
    record = find needle
    [ record, last_result.score ]
  end
  
  # todo fix record.record confusion (should be wrapper.record or smth)
  def find(needle, gather_last_result = true)
    raise Freed if freed?
    free_last_result
    
    if gather_last_result
      last_result.tighteners = tighteners
      last_result.identities = identities
      last_result.blockings = blockings
    end
    
    needle = Wrapper.new :parent => self, :record => needle, :reader => needle_reader
    
    if gather_last_result
      last_result.needle = needle
    end
    
    return if strict_blocking and blockings.none? { |blocking| blocking.encompass? needle }

    encompassed, unencompassed = if strict_blocking and blockings.any?
      haystack.partition do |record|
        blockings.any? do |blocking|
          blocking.encompass?(needle, record) == true
        end
      end
    else
      [ haystack.dup, [] ]
    end
    
    if gather_last_result
      last_result.encompassed = encompassed
      last_result.unencompassed = unencompassed
    end
    
    possibly_identical, certainly_different = if identities.any?
      encompassed.partition do |record|
        identities.all? do |identity|
          answer = identity.identical? needle, record
          answer.nil? or answer == true
        end
      end
    else
      [ encompassed.dup, [] ]
    end
    
    if gather_last_result
      last_result.possibly_identical = possibly_identical
      last_result.certainly_different = certainly_different
    end
    
    similarities = possibly_identical.map do |record|
      needle.similarity record
    end.sort
    
    best_similarity = similarities[-1]
    record = best_similarity.wrapper2
    score = best_similarity.score
    
    if gather_last_result
      last_result.similarities = similarities
      last_result.record = record.record
      last_result.score = score
    end
    
    record.record
  end
  
  def needle_reader
    options[:needle_reader]
  end
  
  def haystack_reader
    options[:haystack_reader]
  end
        
  def strict_blocking
    options[:strict_blocking] || false
  end

  def tighteners
    @tighteners ||= (options[:tighteners] || []).map do |regexp_or_str|
      Tightener.new regexp_or_str
    end
  end

  def identities
    @identities ||= (options[:identities] || []).map do |regexp_or_str|
      Identity.new regexp_or_str
    end
  end

  def blockings
    @blockings ||= (options[:blockings] || []).map do |regexp_or_str|
      Blocking.new regexp_or_str
    end
  end
  
  def freed?
    @freed == true
  end
  
  def free
    free_last_result
    @improver = nil
    
    @options.try :clear
    @haystack.try :clear
    @tighteners.try :clear
    @identities.try :clear
    @blockings.try :clear
    @options = nil
    @haystack = nil
    @tighteners = nil
    @identities = nil
    @blockings = nil
  ensure
    @freed = true
  end
  
  private
  
  def free_last_result
    @last_result.try :free
    @last_result = nil
  end
end
