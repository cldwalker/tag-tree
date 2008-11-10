class Url < ActiveRecord::Base
  acts_as_taggable_on :tags
  validates_presence_of :name
  validates_uniqueness_of :name
  
  class<<self
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
    
    def used_to_tag(max_id, options={})
      words_to_tag = used_but_not_tagged(max_id)
      #eventually include once I can relate verbs + adj to nouns
      derivational = (Node.nonsemantic_tree.descendants -  Node.nonsemantic_node(:noun).descendants).map(&:name)
      #location is one of five top levels
      location = Node.semantic_node(:location).descendants.map(&:name)
      words_to_tag - location - derivational
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
    
    def find_and_change_tag(old_tag, new_tag)
      results = find_tagged_with(old_tag)
      results.each {|e| e.tag_add_and_remove(new_tag, old_tag)}
      puts "Changed tag for #{results.length} records"
    end
  end
  
  def tag_names; tags.map(&:name); end
  
  def tag_add_and_remove(add_list, remove_list)
    self.class.transaction do
      tag_add_and_save(add_list)
      tag_remove_and_save(remove_list)
    end
  end
  
  def tag_add_and_save(tag_list)
    self.tag_list = self.tag_list.add(tag_list, :parse=>true).to_s
    self.save
  end
  
  def tag_remove_and_save(tag_list)
    self.tag_list = self.tag_list.remove(tag_list, :parse=>true).to_s
    self.save
  end
  
  def tag_and_save(tag_list)
    self.tag_list = tag_list
    self.save
  end
  
  def extra_tags
    aoa = tags.map {|e| [e.name, Node.extra_tags(e.name)]}
    p aoa
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