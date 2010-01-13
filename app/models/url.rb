class Url < ActiveRecord::Base
  has_machine_tags :quick_mode=>true, :reverse_has_many=>true, :console=>true
  validates_presence_of :name
  validates_uniqueness_of :name
  can_console_update :only=>['name', 'description', 'tag_list']
  before_save :update_timestamp

  # override has_machine_tags's method to provide a default predicate
  def current_tag_list(list)
    HasMachineTags::TagList.new(list, :quick_mode=>self.quick_mode, :default_predicate=> proc {|*args| default_predicate(*args) })
  end

  def default_predicate(value, namespace)
    mtag_to_match = Tag.build_machine_tag(namespace, '*', value)
    (match = Tag.default_predicates.find {|e| mtag_to_match[/#{e[0].gsub('*', '.*')}/]}) ? match[1] : 'tags'
  end
  
  def update_timestamp
    self.updated_at = (self.class.default_timezone == :utc ? Time.now.utc : Time.now)
  end

  class<<self
    def quick_create(string)
      name, description, tags = string.split(",,")
      create_hash = {:name=>name}
      if tags.nil?
        create_hash[:tag_list] = description
      else
        create_hash[:description] = description
        create_hash[:tag_list] = tags
      end
      create(create_hash)
    end
    
    def tagged_with_count(*args)
      tagged_with(*args).count
    end
    
    def super_tagged_with(*tags)
      options = tags[-1].is_a?(Hash) ? tags.pop : {}
      results = tags.map {|e| Url.tagged_with(e, options.slice(:conditions)) }
      return results.flatten if results.size <= 1
      options[:or] ? results.flatten.uniq : results.inject {|t,v| t & v }
    end
  end  
end
