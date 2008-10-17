require 'g/outline'

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
  
  def edit
    self.class.edit_string(to_otl)
  end
  
  def text_update
    new_otl = edit
    self.class.update_otl(self.id, new_otl)
  end
  
  class <<self
    
    def edit_string(string)
      require 'tempfile'
      tempfile = Tempfile.new('edit')
      File.open(tempfile.path,'w') {|f| f.write(string) }
      system("#{ENV['editor'] || 'vim'} #{tempfile.path}")
      File.read(tempfile.path)
    end

    #level array is an array of level to value arrays
    def otl_to_level_array(otl)
      nodes = otl.split("\n").map {|e| e =~ /^(\t+)?((\d+):)?\s*(.*)$/; {:id=>$3.to_i, :name=>$4, :level=>($1 ? $1.count("\t") : 0) } }
      nodes.map {|e| [e[:level], e]}
    end
    
    # def otl_to_aoa(otl)
    #   nodes = otl_to_level_array(otl)
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
    
    def update_otl(root_id, otl)
      level_array = otl_to_level_array(otl)
      #adding new nodes
      level_array = level_array.map do |level, hash|
        if hash[:id].zero? || hash[:id].blank?
          obj = create(:name=>hash[:name])
          [level, {:id=>obj.id, :name=>obj.name}]
        else
          [level, hash]
        end
      end
      ids_parents = parents_hash_for_level_array(level_array)
      #update root
      new_root = ids_parents.invert[:root]
      ids_parents.delete(new_root)
      if new_root[:id] != root_id
        find(new_root[:id]).move_to_root
        root_id = new_root[:id]
      end
      #update existing nodes to correct parent
      ids_parents.each do |hash, parent|
        node = find(hash[:id]) #|| create(hash[:name])
        if node.parent_id != parent[:id]
          node.move_to_child_of(parent[:id]) 
          puts "Moved node #{node.id} to parent #{parent[:id]}"
        end
      end
      #add/delete nodes
      
      #update node text
      
      #update node order
      # root = find(root_id)
      # update_nodes_children_order(root)
    end
    
    def update_node_order_with_children_hash(current_node, children_hash)
      update_node_order_for_level_array
      children = node.children
    end
    
    def children_hash_for_level_array(level_array)
      level_array.each_with_index do |e, i|
      end
    end
    
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
