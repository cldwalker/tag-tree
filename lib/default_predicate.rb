# Determines default predicates for machine tagged content based on rules in config/machine_tags.yml
class DefaultPredicate
  CONFIG_FILE = RAILS_ROOT + '/config/machine_tags.yml'

  attr_accessor :rule, :global, :filter, :predicate
  def initialize(rule)
    @rule = rule
    @global = !include?(Tag::PREDICATE_DELIMITER)
  end

  class <<self
    # Used by Url to find default predicate
    def find(value, namespace)
      mtag_to_match = Tag.build_machine_tag(namespace, '*', value)
      (match = default_predicates.find {|e| mtag_to_match[/#{e[0].gsub('*', '.*')}/]}) ? match[1] : 'tags'
    end

    # :static_predicates: ?
    # - "*:*=(ruby|perl|sh|python|js|flash|cpp|bash)"
    # - plang
    def config
      @config ||= read_config
    end

    def read_config
      File.exists?(CONFIG_FILE) ? YAML::load_file(CONFIG_FILE) : {:global_predicates=>[], :dynamic_predicates=>[]}
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
      config[:global_predicates].map {|e|
          mtags = Tag.machine_tags(Tag.build_machine_tag('*', e, '*')); ["*:*=(#{mtags.map(&:value).uniq.join('|')})", e]
      }
    end

    def dynamic_predicates
      @dynamic_predicates ||= generate_dynamic_predicates
    end

    def generate_dynamic_predicates
      config[:dynamic_predicates].map {|e|
        mtags = Tag.machine_tags(e); ["#{mtags[0].namespace}:*=(#{mtags.map(&:value).uniq.join('|')})", mtags[0].predicate]
      }
    end

    def machine_tag_reload
      @config = read_config
      @dynamic_predicates = generate_dynamic_predicates
      @global_predicates = generate_global_predicates
    end

    # used to determine what default predicates are set depending on namespace and value
    def default_predicates
      (config[:static_predicates] || [] + dynamic_predicates + global_predicates).
      map {|e| ["^"+e[0]+"$", e[1]] }
    end
  end
end