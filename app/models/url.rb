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
    
    def used_tags(hash={})
      hash = hash.slice(:conditions, :order, :group, :limit, :id)
      if (id = hash.delete(:id))
        hash[:conditions] = "urls.id < #{id}"
      end
      tag_counts(hash).map(&:name)
    end
    
    #should be none
    def used_but_not_semantic(options={})
      arr = used_tags(options) - Node.semantic_tree.descendants.map(&:name)
      unless options[:include_nonsemantic]
        arr -= Node.semantic_node(Node::NONSEMANTIC_NODE).descendants.map(&:name)
      end
      arr
    end
    
    #the fewer here, the more intricate the tag web
    def used_but_not_tagged(options={})
      used_tags(options) - Node.tag_tree.descendants.map(&:name)
    end
    
    #shows parents + predicted semantic nodes
    #tagged_but_not_used() would do the same for the tag tree
    def semantic_but_not_used(options={})
      unused = Node.semantic_tree.descendants.map(&:name) - used_tags(options)
      if options[:exclude_parents]
        unused = Node.semantic_nodes(*unused).select {|e| e.leaf? }.map(&:name)
      end
      unused
    end
  end
  
  def tag_names; tags.map(&:name); end
  
  def tag_and_save(tag_list)
    self.tag_list = tag_list
    self.save
  end
  
  def extra_tags
    semantic_ancestors = tags.map {|e| Node.semantic_ancestors_of(e.name)}.flatten
    tag_ancestors = tags.map {|e| Node.tag_ancestors_of(e.name)}.flatten
    (semantic_ancestors + tag_ancestors).uniq
  end
  
  def all_tags
    (tags.map(&:name) + extra_tags).uniq
  end
  
  #checks to see if tags are related through tag + semantic trees
  def tags_related?
    tag_names.any? {|t| Node.tag_word_ancestor_of?(t, tag_names) }
  end
end