class Tag < ActiveRecord::Base
  has_tag_helper :default_tagged_class=>"Url"
  include HasMachineTags::TagConsole
  #td: doesn't load properly
  # has_machine_tags :quick_mode=>true, :console=>true
  can_console_update :only=>%w{name description}
  class <<self
    def machine_tag_names
      (namespaces + predicates + values).uniq
    end
  
    def search_machine_tag_names(name)
      machine_tag_names.grep(/#{name}/)
    end
    
    def machine_tag(namespace, predicate, value)
      find(:first, :conditions=>{:namespace=>namespace, :predicate=>predicate, :value=>value})
    end

    # default predicate methods
    def machine_tag_config(reload=false)
      @config = reload || @config.nil? ? YAML::load_file(RAILS_ROOT + '/config/machine_tags.yml') : @config
    end

    def global_predicates(reload=false)
      if reload || @global_predicates.nil?
        @global_predicates = machine_tag_config[:global_predicates].map {|e| 
          mtags = machine_tags(Tag.build_machine_tag('*', e, '*')); ["*:*=(#{mtags.map(&:value).uniq.join('|')})", e]}
      end
      @global_predicates
    end

    def wildcard_predicates(reload=false)
      if reload || @wildcard_predicates.nil?
        @wildcard_predicates = machine_tag_config[:dynamic_predicates].map {|e| 
          mtags = machine_tags(e); ["#{mtags[0].namespace}:*=(#{mtags.map(&:value).uniq.join('|')})", mtags[0].predicate]}
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

    def default_predicates
      (machine_tag_config[:static_predicates] || [] + generated_predicates).map {|e| ["^"+e[0]+"$", e[1]]}
    end
  end
end
