require 'g/outline'

module OutlineParser
  def parse_outlines(old_otl, new_otl)
    old_otl_array = self.otl_to_array(old_otl)
    new_otl_array = self.otl_to_array(new_otl)
    new_ids = new_otl_array.map {|e| e[:id]}
    delete_otl_array = old_otl_array.select {|e| !new_ids.include?(e[:id])}
    return new_otl_array, delete_otl_array
  end
  
  def otl_to_array(otl)
    otl.split("\n").map {|e| e =~ /^(\t+)?((\d+):)?\s*(.*)$/; {:id=>$3.to_i, :name=>$4, :level=>($1 ? $1.count("\t") : 0) } }
  end
  
  #level array is an array of level to value arrays
  def otl_to_level_array(otl)
    nodes = otl_to_array(otl)
    nodes.map {|e| [e[:level], e]}
  end
  
  def create_parents_hash(otl_array)
    p otl_array
    hash = {}
    parent = :root
    otl_array.each_with_index do |node, i|
      #NOTE: this condition could be node[:level] = 0 but than have to handle multiple roots ...
      if i == 0
        if node[:level] == 0
          hash[node] = :root
        else
          raise "First node of outline should be root (level 0), instead this node is at level #{node[:level]}"
        end
      else
        hash[node] = find_parent_in_otl_array(otl_array, i) or raise "didn't find parent for #{node.inspect}"
      end
    end
    hash
  end
  
  def find_parent_in_otl_array(otl_array, current_index)
    possible_parents = otl_array.slice(0,current_index).reverse
    for parent in possible_parents
      return parent if parent[:level] < otl_array[current_index][:level]
    end
    nil
  end  
end

class Node < ActiveRecord::Base
  include OutlineParser
  belongs_to :objectable, :polymorphic=>true
  acts_as_nested_set
  
  SEMANTIC_ROOT = 'semantic'
  TAGS_ROOT = 'tags'
  #currently get [[5, [6, [8]], [7]]]
  #should be [[5, [[6, 8], 7]]]
  def to_aoa
    aoa = []
    if self.children.empty?
      aoa << self.id
    else
      aoa = [self.id]
      child_aoa = self.children.map(&:to_aoa)
      aoa << child_aoa
    end
    aoa
  end
  
  def to_otl_array
    otl_to_array(self.to_otl)
  end
  
  def to_otl
    otl = self.to_otl_node
    self.children.each {|e| otl += e.to_otl }
    otl
  end
  
  def to_otl_node
    "\t" * level + "#{self.id}: " + self.name + "\n"
  end
  
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
  
  def text_update
    new_otl = self.class.edit_string(to_otl)
    update_otl(new_otl)
    self.to_otl
  end
  
  def update_otl(new_otl)
    new_otl_array, delete_otl_array = parse_outlines(self.to_otl, new_otl)
    p [new_otl_array, delete_otl_array]
    self.class.transaction do
      new_otl_array = add_otl_nodes(new_otl_array)
      parents_hash = create_parents_hash(new_otl_array)
      p parents_hash
      new_root = parents_hash.invert[:root]
      parents_hash.delete(new_root)
      root_id = update_otl_root(new_root[:id], self.id)
      update_otl_node_levels(parents_hash)
      update_node_attributes(new_otl_array)
      #update node order
      # root = find(root_id)
      # update_nodes_children_order(root)
      
      delete_otl_nodes(delete_otl_array)
    end
  end
  
  def add_otl_nodes(otl_array)
    otl_array.map do |hash|
      if hash[:id].zero? || hash[:id].blank?
        obj = self.class.create(:name=>hash[:name])
        puts "Created node #{obj.id}"
        hash.merge(:id=>obj.id)
      else
        hash
      end
    end
  end
  
  def update_node_attributes(otl_array)
    otl_array.each do |e|
      node = self.class.find(e[:id])
      if node.name != e[:name]
        node.update_attribute :name, e[:name]
        puts "Updated node name for node #{node.id}"
      end
      # unless (tag = node.objectable) && tag.name == e[:name]
      #   node.objectable = Tag.find_or_create_by_name(e[:name])
      #   node.save
      #   puts "Synchronizing tag with node #{node.id}"
      # end
    end
  end
  
  def update_otl_root(new_root, old_root)
    if new_root != old_root
      self.class.find(new_root).move_to_root
      puts "Set node #{new_root} as root"
      new_root
    else
      old_root
    end
  end
  
  def update_otl_node_levels(parents_hash)
    #update existing nodes to correct parent
    parents_hash.each do |hash, parent|
      node = self.class.find(hash[:id])
      if node.parent_id != parent[:id]
        node.move_to_child_of(parent[:id]) 
        puts "Moved node #{node.id} to parent #{parent[:id]}"
      end
    end
  end
  
  def delete_otl_nodes(delete_otl_array)
    delete_otl_array.each {|e| puts "Deleting node #{e[:id]}"; self.class.find(e[:id]).destroy}
  end
  
  # def update_node_order_with_children_hash(current_node, children_hash)
  #   update_node_order_for_level_array
  #   children = node.children
  # end
  # 
  # def children_hash_for_level_array(level_array)
  #   level_array.each_with_index do |e, i|
  #   end
  # end
  
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
  # def tags
  #   arr = self.clone_parents
  #   arr << self.parent
  #   arr.select {|e| e.root.name == TAGS_ROOT}
  # end
  
  def add_tag(tag, context=nil)
    tag_nodes = self.class.tag_tree.find_descendants(tag).select {|e|
      e.parent?
    }
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
  
  def tags
    self.class.tag_tree.find_descendants(self.name).map(&:parent)
  end
  
  def tag_names
    tags.map(&:name)
  end
  
  def tag_trees
    self.tags.each {|e| puts e.to_otl}
    nil
  end
  
  def snode
    unless @snode
      if self.root.name == SEMANTIC_ROOT
        @snode = self
      else
        @snode = self.class.semantic_tree.find_descendants(self.name)[0]
      end
    end
    @snode
  end
  
  def stree
    if snode
      if snode.children.empty?
        puts snode.parent.to_otl
      else
        puts snode.to_otl
      end
    else
      puts "No definition"
    end
  end
  
  def find_descendants(*names)
    descendants.find(:all, :conditions=>%[name IN (#{names.map{|e| "'#{e}'"}.join(',')})])
  end
  
  def parent?; !leaf?; end
  class <<self
    def semantic_tree
      self.find_by_name(SEMANTIC_ROOT)
    end
    def tag_tree
      self.find_by_name(TAGS_ROOT)
    end
    #check for those with tagged items and those that are leaves
    def nonsemantic_tags(exclude_top_levels=false)
      ns_tags = tag_tree.descendants.map(&:name) - semantic_tree.descendants.map(&:name)
      if exclude_top_levels
        ns_tags = tag_tree.find_descendants(*ns_tags).select {|e| e.level > 1 }.map(&:name)
      end
      ns_tags
    end
    
    def unused_tags(exclude_parents=false)
      used_tags = Url.tag_counts.map(&:name)
      unused = semantic_tree.descendants.map(&:name) - used_tags
      if exclude_parents
        unused = semantic_tree.find_descendants(*unused).select {|e| e.leaf? }.map(&:name)
      end
      unused
    end
    
    def edit_string(string)
      require 'tempfile'
      tempfile = Tempfile.new('edit')
      File.open(tempfile.path,'w') {|f| f.write(string) }
      system("#{ENV['editor'] || 'vim'} #{tempfile.path}")
      File.read(tempfile.path)
    end
    
    def update_otl(root_id, new_otl)
      find(root_id).update_otl(new_otl)
    end
    
    
    # def otl_to_aoa(otl)
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
  end
  
end
