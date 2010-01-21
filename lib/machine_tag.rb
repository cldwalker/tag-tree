module MachineTag
  extend self
  # could be more efficient if counting splitters i.e. word.split(/(:|=|\.)/)
  # Alternative to Tag.match_wildcard_machine_tag but for mtag queries
  def parse_machine_tag(word)
    values = word.split(/:|=|\./).delete_if {|e| e.blank? }
    fields = word[/\./] ? [:namespace, :value] :
      word[/:.*=/] ? [:namespace, :predicate, :value] :
      word[/:(.*)/] ? ($1.empty? ? [:namespace] : [:namespace, :predicate]) :
      word[/=$/] ? [:predicate] :
      (word[/(.*)=/] && !$1.empty?) ? [:predicate, :value] : [:value]
    if values.size == fields.size
      fields.zip(values)
    else
      puts("The number of fields (#{fields.inspect}) and values (#{values.inspect}) must be the same.")
      []
    end
  end

  def [](value)
    Hash[*parse_machine_tag(value).flatten]
  end

  def query?(word)
    word[/#{Tag::PREDICATE_DELIMITER}|#{Tag::VALUE_DELIMITER}|\./]
  end
end