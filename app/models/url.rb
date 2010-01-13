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
    def console_find(*args)
      args.flatten!
      if args[0].is_a?(Integer)
        results = args.map {|e| find(e)}
      elsif args[0].is_a?(ActiveRecord::Base)
        results = args
      else
        results = tagged_with(*args)
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
    
    def super_tagged_with(query, *args)
      results = query.split(/\s*\+\s*/).map {|e| Url.tagged_with(e, *args) }
      results.size > 1 ? results.inject {|t,v| t & v } : results.flatten
    end

    def find_and_change_machine_tags(*args)
      options = args[-1].is_a?(Hash) ? args.pop : {}
      results = console_find(args)
      namespace = results.select {|e| 
        nsp = e.tag_list.select {|f| break $1 if f =~ /^(\S+):/}
         break nsp if !nsp.empty?
        false
      }
      if namespace
        results.each {|e|
          new_tag_list = e.tag_list.map {|f|
            f.include?("#{namespace}:") ? f : "#{namespace}:#{f}"
          }
          p [e.id, e.tag_list, new_tag_list]
          if options[:save]
            e.tag_and_save(new_tag_list)
          end
        }
      else
        puts "no namespace detected"
      end
      nil
    end

    def find_and_regex_change_tags(find_args, regex, substitution, options={})
      results = Url.console_find(find_args)
      results.each do |e|
        new_tag_list = e.tag_list.map {|f| f.gsub(regex, substitution)}
        p [e.id, e.tag_list, new_tag_list]
        if options[:save]
          e.tag_and_save(new_tag_list)
        end
      end
      nil
    end
  end  
end
