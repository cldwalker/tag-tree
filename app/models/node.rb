require 'outline/console_editor'

class Node < ActiveRecord::Base
  include Outline::ConsoleEditor
  belongs_to :objectable, :polymorphic=>true
  acts_as_nested_set
  
  #tree which stores is-a relationships between words
  SEMANTIC_ROOT = 'semantic'
  #tree which stores words that haven't made it to semantic tree
  NONSEMANTIC_ROOT = 'nonsemantic'
  #tree which stores categorical/hierarchial relationship between words
  #this name is misleading, words would've been better
  TAG_ROOT = 'tags'
  
  def to_outline_node
    {:level=>level, :id=>id, :text=>name}
  end
  
  #option aliases:c=>:count, :r=>:result, :e=>:extra_tags,:s=>:stats 
  def to_otl(max_level=nil, options={})
    if options[:c]
      tag_counts = Url.used_semantic_tag_counts(options[:c])
      build_outline(max_level) do |node|
        tag_counts[node.name] ? " (#{tag_counts[node.name]})" : ""
      end
    elsif options[:r]
      build_outline(max_level) do |node|
        if node.leaf?
          results = Url.semantic_tagged_with(node.name, :id=>options[:r])
          if results.empty?
            ""
          else
            "\n" + results.map{|e| outline_indent(node.level + 1) + e.to_console}.join("\n")
          end
        else
          ""
        end
      end
    elsif options[:e]
      build_outline(max_level) do |node|
        extra_tags = Node.extra_tags(node.name)
        extra_tags.empty? ? '' : " < #{extra_tags.join(', ')}"
      end
    elsif options[:s]
      build_outline(max_level) do |node|
        " (#{node.descendants.count}d, #{node.children.count}c)"
      end
    elsif options[:u]
      build_outline(max_level) do |node|
        used_tags = Url.used_tags(options[:u])
        if used_tags.include?(node.name)
          " X"
        elsif !(descendants = Node.semantic_descendants_of(node.name).map(&:name) & used_tags).empty?
          " > #{descendants.join(', ')} X"
        else
          ""
        end
      end
    else
      build_outline(max_level)
    end
  end
    
  def view_otl(*args); puts self.to_otl(*args); end
  
  def create_child_node(name)
    node = self.class.create(:name=>name.to_s)
    node.move_to_child_of self.id
    puts self.to_otl
  end
  
  #TODO: merge this with create_node_under()
  #From any tree
  def add_tag(tag, options={})
    tag_nodes = self.class.tag_nodes(tag)
    tag_nodes = tag_nodes.select {|e| e.parent? } if options[:only_parents]
    if tag_nodes.size == 0
      tag_node = self.class.create(:name=>tag)
      tag_node.move_to_child_of self.class.tag_tree.root.id
      tag_node.reload
      tag_nodes << tag_node
      puts "Created tag '#{tag}' in tag tree"
    end
    if tag_nodes.size == 1
      child_node = self.class.create(:name=>self.name)
      child_node.move_to_child_of(tag_nodes[0].id)
      puts "Added node under tag"
    else
      puts "Can't add this tag because it acts as multiple tag parents. Please choose one:"
      tag_nodes.each {|e| puts e.to_otl}
    end
  end
  
  #tags are one level deep whereas tag ancestors recurse all levels
  def tags
    @tags ||= self.class.tag_nodes(self.name).map(&:parent)
  end
  
  def tag_names
    tags.map(&:name)
  end
  
  def extra_tags; self.class.extra_tags(self.name); end
  
  def tagged_by
    @tagged_by ||= self.class.tag_nodes(self.name).map(&:children).flatten
  end
  
  def tagged_by_names; tagged_by.map(&:name); end
  
  def tag_trees(level=1)
    self.tags.each {|e| puts e.to_otl(level)}
    nil
  end
  
  def tagged_by_trees(level=1)
    self.tagged_by.map(&:parent).uniq.each {|e| puts e.to_otl(level)}
    nil
  end
  
  def stats
    descendants.map(&:name).count_hash.sort {|a,b| b[1]<=>a[1] }
  end
  
  #if no children display with focus on level above it
  def smart_tree
    if self.children.empty?
      puts self.parent.to_otl(1)
    else
      puts self.to_otl
    end
  end
  
  def find_descendants(*names)
    descendants.find(:all, :conditions=>%[name IN (#{names.map{|e| "'#{e}'"}.join(',')})])
  end
  
  def find_descendant(name)
    find_descendants(name)[0]
  end
  def parent?; !leaf?; end
  
  def descendants_by_level(level)
    self.descendants.select {|e| 
      e.level == level
    }
  end
  
  def descendant_names; descendants.map(&:name); end
  def parents
    descendants.select {|e| e.parent?}
  end
  def parent_names; parents.map(&:name); end
  def leaf_names; leaves.map(&:name); end
  #assuming in semantic tree
  def semantic_ancestors
    self.ancestors.map(&:name) - [Node::SEMANTIC_ROOT] 
  end
  
  def tag_ancestors
    self.class.tag_ancestors_of(self.name)
  end
  
  def has_semantic_parent?
    !semantic_ancestors.empty?
  end
  
  class <<self
    def change_word(old_word, new_word)
      Url.find_and_change_tag(old_word, new_word)
      update_all(["name = ?", new_word], ["name = ?", old_word])
    end
    
    def check_semantic_words 
      semantic_words = nonsemantic_tree.descendant_names  + semantic_tree.descendant_names
      semantic_words.count_hash.select {|k,v| v > 1}.map {|e| e[0]}
    end
    
    def nonsemantic_tree
      find_by_name(NONSEMANTIC_ROOT)
    end
    
    def nonsemantic_node(name)
      nonsemantic_tree.find_descendant(name)
    end
    
    def semantic_tree
      self.find_by_name(SEMANTIC_ROOT)
    end
    
    def semantic_names(level=nil)
      level ? semantic_tree.descendants_by_level(level).map(&:name) : semantic_tree.descendants.map(&:name)
    end
    
    def semantic_node(name)
      semantic_tree.find_descendant(name)
    end
    
    def semantic_nodes(*names)
      return [] if names.empty?
      semantic_tree.find_descendants(*names)
    end
    
    def semantic_ancestors_of(name)
      if (node = semantic_node(name))
        node.semantic_ancestors
      else
        []
      end
    end
    
    def semantic_descendants_of(name)
      if (node = semantic_node(name))
        node.descendants
      else
        []
      end
    end
    
    def create_node_under(parent_node, new_name, parent_name=nil)
      if parent_node
        parent_node.create_child_node(new_name)
      else
        message = parent_name ? "Parent node '#{parent_name}' not found" : "Parent node not found"
        puts message
      end
    end
    
    def create_nonsemantic_node(*args)
      options = args[-1].is_a?(Hash) ? args.pop : {}
      parent_name = options[:type] || :noun
      parent_node = nonsemantic_node(parent_name)
      args.each {|e| create_node_under(parent_node, e, parent_name) }
    end
    
    def create_semantic_node_under(new_name, parent_name=nil)
      if parent_name
        parent_node = semantic_node(parent_name)
        create_node_under(parent_node, new_name, parent_name)
      else
        semantic_root = semantic_tree
        create_node_under(semantic_root, new_name, semantic_root.name)
      end
    end
    
    def create_tag_node_under(new_name, parent_name)
      parent_node = tag_node(parent_name)
      create_node_under(parent_node, new_name, parent_name)
    end
    
    #?: replace create_tag_node_under
    def create_tag_node_and_parent_node(new_name, parent_name)
      parent_name = parent_name.to_s
      parent_node = tag_node(parent_name)
      if parent_node.nil?
        parent_node = create(:name=>parent_name)
        parent_node.move_to_child_of tag_tree.root.id
      end
      create_node_under(parent_node, new_name, parent_name)
    end
    
    def tag_tree
      self.find_by_name(TAG_ROOT)
    end
    
    def tag_names
      tag_tree.descendants.map(&:name)
    end
    
    def tag_node(name)
      tag_tree.find_descendant(name)
    end
    
    def tag_nodes(name)
      tag_tree.find_descendants(name)
    end
    
    def tag_ancestors_of(name)
      tag_nodes(name).map(&:ancestors).flatten.map(&:name).reverse.uniq - [Node::TAG_ROOT]
    end
    
    #tag word == tag_nodes
    def tag_word_ancestor_of?(tag, possible_children)
      tag_children = tag_nodes(tag).map(&:descendants).flatten.map(&:name).uniq
      semantic_tag_children = semantic_nodes(*tag_children).map(&:descendants).flatten.map(&:name).uniq
      tag_children += semantic_tag_children
      diff = possible_children & tag_children
      puts "Word '#{tag}' is ancestor of: #{diff.inspect}" unless diff.empty?
      !diff.empty?
    end

    def extra_tags(name, verbose=false)
      extra = []
      semantic_ancestors = semantic_ancestors_of(name)
      extra << semantic_ancestors
      puts "Semantic ancestors: #{semantic_ancestors.join(',')}" if verbose && !semantic_ancestors.empty?
      semantic_ancestors.each do |e| 
        results = tag_ancestors_of(e)
        puts "Tag ancestors of #{e}: #{results.join(',')}" if verbose && !results.empty?
        extra << results
      end
      
      tag_ancestors = tag_ancestors_of(name)
      extra << tag_ancestors
      puts "Tag ancestors: #{tag_ancestors.join(',')}" if verbose && !tag_ancestors.empty?
      extra.flatten.uniq
    end

    def status(name)
      if (node = semantic_node(name))
        puts "Semantic:"
        node.smart_tree
      elsif (node = nonsemantic_node(name))
        puts "Nonsemantic #{node.parent.name}"
      else
        puts "Semantic: not found"
      end
      if (node = tag_node(name))
        puts "#{node.tags.length} Tags: #{node.tag_names.join(', ')}"
        node.tag_trees
        puts "#{node.tagged_by.length} Tagged Bys: #{node.tagged_by_names.join(', ')}"
        node.tagged_by_trees
      else
        puts "No tags or tagged by"
      end
    end
    
    #check for nodes that are tagged but not semantically defined
    def tagged_but_not_semantic(exclude_top_levels=false)
      ns_tags = tag_tree.descendants.map(&:name) - semantic_tree.descendants.map(&:name)
      if exclude_top_levels
        ns_tags = tag_tree.find_descendants(*ns_tags).select {|e| e.level > 1 }.map(&:name)
      end
      ns_tags.uniq
    end    
  end
  
end

__END__

####failed aoa conversions####
#require 'g/outline'
#currently get [[5, [6, [8]], [7]]] but should be [[5, [[6, 8], 7]]]
# def to_aoa
#   aoa = []
#   if self.children.empty?
#     aoa << self.id
#   else
#     aoa = [self.id]
#     child_aoa = self.children.map(&:to_aoa)
#     aoa << child_aoa
#   end
#   aoa
# end
# def self.otl_to_aoa(otl)
#   nodes = otl_to_array(otl)
#   aoa = []
#   child_aoa = []
#   nodes.each_with_index do |e, i|
#     #has children
#     if nodes[i+1] && nodes[i+1][:level] > e[:level]
#       aoa << [ e.id, get_otl_children(e)]
#     else
#       aoa << e.id
#     end
#   end
#   aoa
# end
  

####Assuming many trees####
  #nodes with same name
  def clones
    unless @clones
      @clones = self.class.find_all_by_name(self.name)
      @clones.delete(self)
    end
    @clones
  end

  def clone_parents; self.clones.map(&:parent); end
  #returns tree roots
  def clone_trees; self.clones.map(&:root); end


###Later: TafelTree view methods#####
def to_ttree
  tree = []
  tree << build_ttree_node(tree)
  tree
end

def build_ttree_node(tree)
  node = {:id=>self.id, :txt=>name, :editable=>true, :level=>self.level}
  if !self.children.empty?
    children_nodes = self.children.map {|e| e.build_ttree_node(tree)}
    node[:items] = children_nodes
  end
  node
end

def update_ttree(root_id, ttree)
  ids_parents = ids_and_parents_hash(ttree)
  root_id = ids_parents.invert[:root]
  ids_parents.delete(root_id)
  root = Item.find(root_id)
  if root_id != root.id
    Item.find(root.id).move_to_root
  end
  ids_parents.each do |id, parent_id|
    item = Item.find(id)
    item.move_to_child_of(parent_id) if item.parent_id != parent_id
  end
end

def ids_and_parents_hash(ttree)
  hash = {}
  parent = :root
  parse_level(ttree, parent, hash)
  hash
end

def parse_level(nodes, parent, hash)
  nodes.each do |e|
    hash[e['id']] = parent
    parse_level(e['items'],e['id'],hash) if e['items']
  end
end

###Possible console editor enhancement####
# def update_node_attributes(otl_array)
  #super
  # otl_array.each do |e|
  #   node = self.class.find(e[:id])
    # unless (tag = node.objectable) && tag.name == e[:text]
    #   node.objectable = Tag.find_or_create_by_name(e[:text])
    #   node.save
    #   console_message "Synchronizing tag with node #{node.id}"
    # end
#   end
# end
