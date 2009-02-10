require File.join(File.dirname(__FILE__), 'test_helper')
require 'has_machine_tags/tag'

class TagTest < Test::Unit::TestCase
  test "tag is a tag" do
    assert Tag.new(:name=>'cool').is_a?(Tag)
  end
end
