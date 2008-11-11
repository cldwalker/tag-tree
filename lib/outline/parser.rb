
# Provides parse_outlines() and create_parents_hash() for parsing
# and build_otl() for generating outlines
module Outline
  module Parser
  def parse_outlines(old_otl, new_otl)
    old_otl_array = self.otl_to_array(old_otl)
    new_otl_array = self.otl_to_array(new_otl)
    new_ids = new_otl_array.map {|e| e[:id]}
    delete_otl_array = old_otl_array.select {|e| !new_ids.include?(e[:id])}
    return new_otl_array, delete_otl_array
  end
  
  def otl_to_array(otl)
    otl.split(record_separator).map {|e| string_to_otl_node(e) }
  end
  
  def record_separator; "\n"; end
  def indent_character; "\t"; end
  
  def otl_indent(indent_level); indent_character * indent_level; end
  def string_to_otl_node(string)
    string =~ /^(#{indent_character}+)?((\d+):)?\s*(.*)$/
    {:id=>$3.to_i, :text=>$4, :level=>($1 ? $1.count(indent_character) : 0) }
  end
  #otl_node is a hash of node properties
  def otl_node_to_string(otl_node)
    otl_indent(otl_node[:level]) + "#{otl_node[:id]}: " + otl_node[:text] + record_separator
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
  
  #assumes children() and to_otl_node() method for inheriting object
  def build_otl(max_level=nil, otl_level=0, &block)
    otl = otl_node_to_string(self.to_otl_node)
    if block_given?
      otl = otl.chomp(record_separator) + yield(self) + record_separator
    end
    otl_level += 1
    return otl if max_level && otl_level > max_level
    self.children.each {|e| otl += e.build_otl(max_level,otl_level, &block) }
    otl
  end
  end
end
