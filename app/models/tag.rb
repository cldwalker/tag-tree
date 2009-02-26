class Tag < ActiveRecord::Base
  has_tag_helper :default_tagged_class=>"Url"
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
  end
end
