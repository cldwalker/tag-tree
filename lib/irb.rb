#this file contains handy methods and aliases to be used from the console
U = Url
Tr = Tree
T = Tag
N = Node

ActiveRecord::Base.class_eval %[
  def self.f(*args); self.find(*args); end
  def self.fn(*args); self.find_by_name(*args); end
  def self.ftw(*args); self.find_tagged_with(*args);end
  def self.stw(*args); self.semantic_tagged_with(*args);end
]

Node.class_eval %[
  def self.st(value); self.status(value); end
  def to; puts self.to_otl; end
  def u; puts self.text_update; end
  alias_method :tn, :tag_names
  alias_method :tt, :tag_trees
  alias_method :fds, :find_descendants
  alias_method :fd, :find_descendant
]
  
def tn(name)
  Node.tag_nodes(name)
end

def sn(name)
  Node.semantic_node(name)
end

def tags(id_or_name)
  node = Node.find_by_id(id_or_name) || Node.find_by_name(id_or_name)
  node.tag_names
end

class Array
  def amap(*fields)
    map {|e| fields.map {|field| e.send(field) }}
  end
end