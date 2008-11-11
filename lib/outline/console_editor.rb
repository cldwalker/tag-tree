require 'outline/parser'

# depends on methods from Outline::Parser and
# following tree methods: move_to_root() and move_to_child_of()
module Outline
  module ConsoleEditor
  include Outline::Parser
  #change to your own editor
  def my_editor
    "vim -c 'setf vo_base'"
  end
  def edit_string(string)
    require 'tempfile'
    tempfile = Tempfile.new('edit')
    File.open(tempfile.path,'w') {|f| f.write(string) }
    system("#{my_editor} #{tempfile.path}")
    File.read(tempfile.path)
  end
  
  def text_update
    new_otl = edit_string(build_otl)
    update_otl(new_otl)
    self.build_otl
  end
  
  def update_otl(new_otl)
    new_otl_array, delete_otl_array = parse_outlines(self.build_otl, new_otl)
    # p ["ADD: ", new_otl_array]
    p ["DELETE: ", delete_otl_array]
    self.class.transaction do
      new_otl_array = add_otl_nodes(new_otl_array)
      parents_hash = create_parents_hash(new_otl_array)
      # p parents_hash
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
        obj = self.class.create(:name=>hash[:text])
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
      if node.name != e[:text]
        node.update_attribute :name, e[:text]
        puts "Updated node name for node #{node.id}"
      end
      # unless (tag = node.objectable) && tag.name == e[:text]
      #   node.objectable = Tag.find_or_create_by_name(e[:text])
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
    delete_otl_array.each {|e| 
      if (node = self.class.find_by_id(e[:id]))
        node.destroy
        puts "Deleted node #{e[:id]}"
      end
    }
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
  end
end