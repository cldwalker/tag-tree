# Determines default predicates for machine tagged content based on rules in config/machine_tags.yml
class DefaultPredicate
  class <<self
    # Used by Url to find default predicate
    def find(value, namespace)
      mtag_to_match = Tag.build_machine_tag(namespace, '*', value)
      (match = default_predicates.find {|e| mtag_to_match[/#{e[0].gsub('*', '.*')}/]}) ? match[1] : 'tags'
    end

    # default predicate methods
    def machine_tag_config(reload=false)
      @config = reload || @config.nil? ? YAML::load_file(RAILS_ROOT + '/config/machine_tags.yml') : @config
    end

    def global_predicates(reload=false)
      if reload || @global_predicates.nil?
        @global_predicates = machine_tag_config[:global_predicates].map {|e| 
          mtags = Tag.machine_tags(Tag.build_machine_tag('*', e, '*')); ["*:*=(#{mtags.map(&:value).uniq.join('|')})", e]}
      end
      @global_predicates
    end

    def wildcard_predicates(reload=false)
      if reload || @wildcard_predicates.nil?
        @wildcard_predicates = machine_tag_config[:dynamic_predicates].map {|e| 
          mtags = Tag.machine_tags(e); ["#{mtags[0].namespace}:*=(#{mtags.map(&:value).uniq.join('|')})", mtags[0].predicate]}
      end
      @wildcard_predicates
    end
    
    def machine_tag_reload
      machine_tag_config(true)
      generated_predicates(true)
    end

    def generated_predicates(reload=false)
      global_predicates(reload) + wildcard_predicates(reload)
    end

    # used to determine what default predicates are set depending on namespace and value
    def default_predicates
      (machine_tag_config[:static_predicates] || [] + generated_predicates).map {|e| ["^"+e[0]+"$", e[1]]}
    end
  end
end