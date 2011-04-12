class LooseTightDictionary
  module ExtractRegexp #:nodoc: all
    def extract_regexp(regexp_or_str)
      case regexp_or_str
      when ::Regexp
        regexp_or_str
      when ::String
        regexp_from_string regexp_or_str
      else
        raise ::ArgumentError, "Expected regexp or string"
      end
    end
    
    REGEXP_DELIMITERS = {
      '%r{' => '}',
      '/' => '/'
    }
    def regexp_from_string(str)
      delim_start, delim_end = REGEXP_DELIMITERS.detect { |k, v| str.start_with? k }.map { |delim| ::Regexp.escape delim }
      %r{\A#{delim_start}(.*)#{delim_end}([^#{delim_end}]*)\z} =~ str.strip
      content = $1
      options = $2
      content.gsub! '\\/', '/'
      ignore_case = options.include?('i') ? ::Regexp::IGNORECASE : nil
      multiline = options.include?('m') ? ::Regexp::MULTILINE : nil
      extended = options.include?('x') ? ::Regexp::EXTENDED : nil
      ::Regexp.new content, (ignore_case||multiline||extended)
    end
  end
end
