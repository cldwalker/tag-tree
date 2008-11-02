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
    
    def used_but_not_semantic(options={})
      arr = used_tags(options) - Node.semantic_tree.descendants.map(&:name)
      unless options[:include_nonsemantic]
        arr -= Node.semantic_node(:nonsemantic).descendants.map(&:name)
      end
      arr
    end
    
    def used_but_not_tagged(options={})
      used_tags(options) - Node.tag_tree.descendants.map(&:name)
    end
    
    def semantic_but_not_used(options={})
      unused = Node.semantic_tree.descendants.map(&:name) - used_tags(options)
      if options[:exclude_parents]
        unused = Node.semantic_nodes(*unused).select {|e| e.leaf? }.map(&:name)
      end
      unused
    end
  end
  
  def tag_names; tags.map(&:name); end
end