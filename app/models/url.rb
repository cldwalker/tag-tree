class Url < ActiveRecord::Base
  acts_as_taggable_on :tags
  validates_presence_of :name
  validates_uniqueness_of :name
  
  class<<self
    #looks up semantic 
    def semantic_tagged_with(*args)
      children = Node.semantic_tree.find_descendant(args[0]).children.map(&:name)
      puts "Including immediate children : #{children.join(',')}" if children.size > 0
      args[0] = children << args[0]
      self.find_tagged_with(*args)
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
    
    #should be none
    def used_but_not_semantic(max_id, options={})
      arr = used_tags(max_id) - Node.semantic_names
      unless options[:include_nonsemantic]
        arr -= Node.semantic_node(Node::NONSEMANTIC_NODE).descendants.map(&:name)
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
      derivational = (Node.semantic_node(Node::NONSEMANTIC_NODE).descendants -  Node.semantic_node(:noun).descendants).map(&:name)
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
  end
  
  def tag_names; tags.map(&:name); end
  
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
    semantic_ancestors = tags.map {|e| Node.semantic_ancestors_of(e.name)}.flatten
    tag_ancestors = tags.map {|e| Node.tag_ancestors_of(e.name)}.flatten
    semantic_tag_ancestors = semantic_ancestors.map {|e| Node.tag_ancestors_of(e)}.flatten
    (semantic_ancestors + tag_ancestors + semantic_tag_ancestors).uniq
  end
  
  def all_tags
    (tags.map(&:name) + extra_tags).uniq
  end
  
  #checks to see if tags are related through tag + semantic trees
  def tags_related?
    tag_names.any? {|t| Node.tag_word_ancestor_of?(t, tag_names) }
  end
end