
# This module provides parse_outlines() and create_parents_hash() for outline parsing
# and build_outline() for generating outlines.
# To be usable this module needs to be included and have string_to_outline_node()
# and outline_node_to_string() overriden.
# build_outline() has its own interface expectations.
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
    otl.split(record_separator).map {|e| string_to_outline_node(e) }
  end
  
  def record_separator; "\n"; end
  def indent_character; "\t"; end
  def outline_indent(indent_level); indent_character * indent_level; end
  
  def string_to_outline_node(string); raise "This abstract method needs to be overriden."; end
  #should return a hash with :level, :text and :id keys
  def outline_node_to_string(otl_node); raise "This abstract method needs to be overriden."; end
  
  #level array is an array of level to value arrays
  def otl_to_level_array(otl)
    nodes = otl_to_array(otl)
    nodes.map {|e| [e[:level], e]}
  end
  
  def create_parents_hash(otl_array)
    # logger.debug "PARENTS:" + otl_array.inspect
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
  
  #assumes inheriting object has children() and to_outline_node() methods
  def build_outline(max_level=nil, otl_level=0, &block)
    otl = outline_node_to_string(self.to_outline_node)
    if block_given?
      otl = otl.chomp(record_separator) + yield(self) + record_separator
    end
    otl_level += 1
    return otl if max_level && otl_level > max_level
    self.children.each {|e| otl += e.build_outline(max_level,otl_level, &block) }
    otl
  end
  end
end
