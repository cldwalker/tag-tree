# Determines default predicates for machine tags by generating filters (regexs) from rules in config/machine_tags.yml
# Note: This class doesn't consistently build machine tags with Tag.build_machine_tag()
class DefaultPredicate
  CONFIG_FILE = Rails.root + 'config/machine_tags.yml'

  attr_accessor :rule, :global, :predicate
  def initialize(rule)
    @rule = rule
    @global = !Tag.machine_tag?(@rule)
    @predicate = @global ? @rule : Tag.split_machine_tag(@rule)[1]
  end

  def machine_tags
    @machine_tags ||= Tag.machine_tags( @global ? Tag.build_machine_tag('*', @rule, '*') : @rule )
  end

  def values
    machine_tags.map {|e| e.value }.uniq - (DefaultPredicate.config[:predicate_exceptions][rule] || [])
  end

  def filter
    @filter ||= begin
      @global ? "*:*=(#{values.join('|')})" : "#{machine_tags[0].namespace}:*=(#{values.join('|')})"
    end
  end

  class <<self
    # Used by Url to find default predicate
    def find(value, namespace)
      mtag_to_match = Tag.build_machine_tag(namespace, '*', value)
      (match = predicates.find {|e| mtag_to_match[/^#{e.filter.gsub('*', '.*')}$/] }) ?
        match.predicate : 'tags'
    end

    def config
      @config ||= read_config
    end

    def read_config
      File.exists?(CONFIG_FILE) ? YAML::load_file(CONFIG_FILE) :
        { :global_predicates=>[], :dynamic_predicates=>[], :predicate_exceptions=>{} }
    end

    def add_rules(*rules)
      new_config = config.dup
      rules.each {|e|
        e.include?(Tag::PREDICATE_DELIMITER) ? new_config[:dynamic_predicates] << e :
          new_config[:global_predicates] << e
      }
      File.open(CONFIG_FILE, 'w') {|f| f.write(new_config.to_yaml) }
      new_config
    end

    def global_predicates
      @global_predicates ||= generate_global_predicates
    end

    def generate_global_predicates
      config[:global_predicates].map {|e| new(e) }
    end

    def dynamic_predicates
      @dynamic_predicates ||= generate_dynamic_predicates
    end

    def generate_dynamic_predicates
      config[:dynamic_predicates].map {|e| new(e) }
    end

    def reload
      @config = read_config
      @dynamic_predicates = generate_dynamic_predicates
      @global_predicates = generate_global_predicates
    end

    # used to determine what default predicates are set depending on namespace and value
    # :static_predicates: ["*:*=(ruby|perl|sh|python|js|flash|cpp|bash)"] ?
    def predicates
      dynamic_predicates + global_predicates
    end
  end
end