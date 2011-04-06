require 'helper'

class TestExtractRegexp < Test::Unit::TestCase
  def test_001_regexp
    i = LooseTightDictionary::Identity.new %r{\A\\?/(.*)etc/mysql\$$}
    assert_equal %r{\A\\?/(.*)etc/mysql\$$}, i.regexp
  end
  
  def test_002_regexp_from_string
    i = LooseTightDictionary::Identity.new '%r{\A\\\?/(.*)etc/mysql\$$}'
    assert_equal %r{\A\\?/(.*)etc/mysql\$$}, i.regexp
  end
  
  def test_003_regexp_from_string_using_slash_delim
    i = LooseTightDictionary::Identity.new '/\A\\\?\/(.*)etc\/mysql\$$/'
    assert_equal %r{\A\\?/(.*)etc/mysql\$$}, i.regexp
  end
end
