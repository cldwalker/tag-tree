require 'g/outline'

module OutlineParser
  def otl_to_array(otl)
    otl.split("\n").map {|e| e =~ /^(\t+)?((\d+):)?\s*(.*)$/; {:id=>$3.to_i, :name=>$4, :level=>($1 ? $1.count("\t") : 0) } }
  end
  
  #level array is an array of level to value arrays
  def otl_to_level_array(otl)
    nodes = otl_to_array(otl)
    nodes.map {|e| [e[:level], e]}
  end  
end

class Node < ActiveRecord::Base
  belongs_to :objectable, :polymorphic=>true
  acts_as_nested_set
  
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
    # add_array, delete_array, parents_hash = parse_outlines(old_otl, new_otl)
    old_otl_array = self.to_otl_array.dup
    p ["OLD:", old_otl_array]
    self.class.transaction do
      new_otl_array = otl_to_array(new_otl)
      existing_ids = new_otl_array.map {|e| e[:id]}
      delete_otl_array = old_otl_array.select {|e| !existing_ids.include?(e[:id])}
      # add_otl_array = new_otl_array.select {|e| ! old}
      level_array = otl_to_level_array(new_otl)
      level_array = add_otl_level_array(level_array)
      p ["NEW:", level_array.map {|e| e[1]}]
      parents_hash = parents_hash_for_level_array(level_array)
      p ["PARENTS:", parents_hash]
      new_root = parents_hash.invert[:root]
      parents_hash.delete(new_root)
      root_id = update_otl_root(new_root[:id], root_id)
      update_otl_node_levels(parents_hash)
      #update node text
      #update node order
      # root = find(root_id)
      # update_nodes_children_order(root)
      
      delete_otl_nodes(delete_otl_array)
    end
  end
  
  def add_otl_level_array(level_array)
    level_array.map do |level, hash|
      if hash[:id].zero? || hash[:id].blank?
        obj = create(:name=>hash[:name])
        puts "Created node #{obj.id}"
        [level, {:id=>obj.id, :name=>obj.name}]
      else
        [level, hash]
      end
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
  
  # def update_node_order_with_children_hash(current_node, children_hash)
  #   update_node_order_for_level_array
  #   children = node.children
  # end
  # 
  # def children_hash_for_level_array(level_array)
  #   level_array.each_with_index do |e, i|
  #   end
  # end
  
  def parents_hash_for_level_array(level_array)
    hash = {}
    parent = :root
    level_array.each_with_index do |e, i|
      if i == 0
        hash[e[1]] = :root
      else
        hash[e[1]] = find_parent_in_level_array(level_array, i) or raise "didn't find parent for #{e.inspect}"
      end
    end
    hash
  end
  
  def find_parent_in_level_array(level_array, current_index)
    possible_parents = level_array.slice(0,current_index).reverse
    for parent in possible_parents
      return parent[1] if parent[0] < level_array[current_index][0]
    end
    nil
  end
  
  def delete_otl_nodes(delete_otl_array)
    delete_otl_array.each {|e| puts "Deleting node #{e[:id]}"; self.class.find(e[:id]).destroy}
  end
  
  class <<self
    
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
