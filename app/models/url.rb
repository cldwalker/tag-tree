class Url < ActiveRecord::Base
  has_machine_tags :quick_mode=>true, :reverse_has_many=>true, :console=>true
  validates_presence_of :name
  validates_uniqueness_of :name
  can_console_update :only=>['name', 'description', 'tag_list']
  before_save :update_timestamp
  
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
    def console_find(*queries)
      options = queries[-1].is_a?(Hash) ? queries.pop : {}
      queries = queries[0].to_a if queries[0].is_a?(Range)
      if queries[0].is_a?(Integer)
        results = queries.map {|e| find(e) rescue nil }.compact
      else
        results = queries[0] ? find_by_regexp(queries[0], options[:columns] || ['name']).
          find(:all, options.slice(:limit, :offset, :conditions)) :
          find(:all, options.slice(:limit, :offset, :conditions))
      end
      results
    end
      
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

    def gsub_tags(urls, regex, substitution, options={})
      urls.map do |e|
        new_tag_list = e.tag_list.map {|f| f.gsub(regex, substitution)}
        if options[:save]
          e.tag_and_save(new_tag_list)
        end
        {:id=>e.id, :old_tags=>e.tag_list, :new_tags=>new_tag_list.join(', ')}
      end
    end
  end  
end
