require 'outline/parser'
module Outline
  module NodeParser
    include Parser
    
    def string_to_outline_node(string)
      string =~ /^(#{indent_character}+)?((\d+):)?\s*(.*)$/
      {:id=>$3.to_i, :text=>$4, :level=>($1 ? $1.count(indent_character) : 0) }
    end
    
    #otl_node is a hash of node properties
    def outline_node_to_string(otl_node)
      outline_indent(otl_node[:level]) + "#{otl_node[:id]}: " + otl_node[:text] + record_separator
    end
  end
end