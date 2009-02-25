class Tag < ActiveRecord::Base
  has_tag_helper :default_tagged_class=>"Url"
  def self.machine_tag_names
    (namespaces + predicates + values).uniq
  end
  
  def self.search_machine_tag_names(name)
    machine_tag_names.grep(/#{name}/)
  end
end
