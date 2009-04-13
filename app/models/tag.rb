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

    def machine_tag_config(reload=false)
      @config = reload || @config.nil? ? YAML::load_file(RAILS_ROOT + '/config/machine_tags.yml') : @config
    end
  end
end
