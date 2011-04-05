class LooseTightDictionary
  class I
    attr_reader :regexp, :str, :case_sensitive, :identity
    def initialize(regexp, str, case_sensitive)
      @regexp = regexp
      @str = str
      @identity = regexp.match(str).captures.compact.join
      @identity = @identity.downcase if case_sensitive
    end
  end
end
