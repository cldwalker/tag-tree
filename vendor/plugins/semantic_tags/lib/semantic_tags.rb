current_dir = File.dirname(__FILE__)
$:.unshift(current_dir) unless $:.include?(current_dir) || $:.include?(File.expand_path(current_dir))

%w{models}.each do |dir|
  path = File.join(File.dirname(__FILE__), 'app', dir)
  $LOAD_PATH << path
  ActiveSupport::Dependencies.load_paths << path
  ActiveSupport::Dependencies.load_once_paths.delete(path)
end


module SemanticTags
  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
  end

  module ClassMethods
    def semantic_tags(options={})
      self.class_eval do
        extend SingletonMethods
        include InstanceMethods
        #some methods depended on this call:
        #acts_as_taggable_on :tags, :facet_types
      end
    end
  end
  module SingletonMethods
    #looks up semantic 
    def semantic_tagged_with(tags, options={})
      children = (parent = Node.semantic_node(tags)) ? parent.descendants.map(&:name) : []
      if children.size > 0
        puts "Including #{tags}'s children in query : #{children.join(',')}" 
        tags = children + [tags]
      end
      results = self.find_tagged_with(tags)
      #hack: since passing id condition doesn't work?
      options[:id] ? results.select {|e| e.id <= options[:id]} : results
    end
    
    #should be empty otherwise tags are redundant
    def tags_related(max_id)
      find(:all, parse_conditions(max_id)).select {|e| e.tags_related? }
    end
    
    def used_tags(max_id=nil)
      max_id ? tag_counts(parse_conditions(max_id)).map(&:name) : tag_counts.map(&:name)
    end
    
    def parse_conditions(max_id, hash={})
      hash.merge!(:id=>max_id)
      hash = hash.slice(:conditions, :order, :group, :limit, :id)
      if (id = hash.delete(:id))
        hash[:conditions] = "urls.id <= #{id}"
      end
      hash
    end
    
    def used_tag_counts(max_id)
      tag_counts(parse_conditions(max_id)).map {|e| [e.name, e.count]}.sort {|a,b| b[1]<=>a[1] }
    end
    
    def used_semantic_tag_counts(max_id)
      tag_counts = Hash[*used_tag_counts(max_id).flatten]
      Node.semantic_tree.parents.each do |e|
        descendants = e.descendants.map(&:name)
        parent_total = tag_counts.slice(*descendants).values.sum
        tag_counts[e.name] = parent_total if parent_total > 0
      end
      tag_counts
    end
    
    def tag_stats(max_id)
      used_semantic_tag_counts(max_id).to_a.sort {|a,b| b[1]<=>a[1] }
    end
    
    def facet_stats(url_array)
      total_records = url_array.length
      facets = url_array.map {|e| e.extra_tags(true) }.flatten
      total_facets = facets.size
      facet_hash = facets.count_hash
      puts "FACET STATS for #{total_records} records, #{total_facets} facets (#{facets.uniq.size} unique)\nPercentages are calculated per total facets and total records\n\n"
      facet_hash.each do |facet, count|
        facet_percent = sprintf('%.0f', count /total_facets.to_f * 100)
        record_percent = sprintf('%.0f', count/ total_records.to_f * 100)
        puts %[#{facet}: #{facet_percent}% / #{record_percent}%]
      end
    end
    
    #should be none
    def used_but_not_semantic(max_id, options={})
      arr = used_tags(max_id) - Node.semantic_names
      unless options[:include_nonsemantic]
        arr -= Node.nonsemantic_tree.descendants.map(&:name)
      end
      arr
    end
    
    #the fewer here, the more intricate the tag web
    def used_but_not_tagged(max_id, options={})
      used = used_tags(max_id)
      tag_node_names = Node.tag_names
      used_semantically = used.select {|e| !(Node.semantic_ancestors_of(e) & tag_node_names).empty? }
      used - used_semantically - tag_node_names
    end
    
    def tags_to_tag
      [:location, :learning_type, :td, :site, :site_type, :lang]
    end
    
    def used_to_tag(max_id, options={})
      words_to_tag = used_but_not_tagged(max_id)
      #eventually include once I can relate verbs + adj to nouns
      derivational = (Node.nonsemantic_tree.descendants -  Node.nonsemantic_node(:noun).descendants).map(&:name)
      #location is one of five top levels
      td_tag_descendants = tags_to_tag.map {|e| Node.semantic_node(e).descendants.map(&:name) }.flatten
      words_to_tag - td_tag_descendants - derivational
    end
    
    #shows parents + predicted semantic nodes
    #tagged_but_not_used() would do the same for the tag tree
    def semantic_but_not_used(max_id, options={})
      unused = Node.semantic_names - used_tags(max_id)
      if options[:exclude_parents]
        unused = Node.semantic_nodes(*unused).select {|e| e.leaf? }.map(&:name)
      end
      unused
    end
  end
  
  module InstanceMethods
    def tag_names; tags.map(&:name); end

    def facet_type_and_save(ftype_list)
      self.facet_type_list = ftype_list
      self.save
    end

    def extra_tags(verbose=false)
      aoa = tags.map {|e| [e.name, Node.extra_tags(e.name)]}
      puts  "#{id}: #{aoa.inspect}" if verbose
      aoa.map {|e| e[1]}.flatten.uniq
    end

    def all_tags
      (tags.map(&:name) + extra_tags).uniq
    end

    #checks to see if tags are related through tag + semantic trees
    def tags_related?
      tag_names.any? {|t| Node.tag_word_ancestor_of?(t, tag_names) }
    end

    def to_console
      "#{self.id}: #{self.name} : #{self.tag_list}"
    end
  end
end
