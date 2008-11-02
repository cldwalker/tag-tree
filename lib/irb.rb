#this file contains handy methods and aliases to be used from the console
require 'pp'

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
  def to(*args); puts self.to_otl(*args); end
  def u; puts self.text_update; end
  alias_method :tn, :tag_names
  alias_method :tbn, :tagged_by_names
  alias_method :tt, :tag_trees
  alias_method :tbt, :tagged_by_trees
  alias_method :fds, :find_descendants
  alias_method :fd, :find_descendant
]
  
def st(name)
  Node.status(name)
end

def tn(name)
  Node.tag_node(name)
end

def sn(name)
  Node.semantic_node(name)
end

def tags(id_or_name)
  node = Node.find_by_id(id_or_name) || Node.find_by_name(id_or_name)
  node.tag_names
end

#url-paged
def up(offset=0, limit=20)
  columns = [:id, :name, :tag_names]
  uf(offset, limit).amap(*columns)
end

#url-find
def uf(offset=0, limit=20)
  Url.find(:all, :offset=>offset, :limit=>limit)
end

#urls-tagged
def ut(*args)
  tag = args.shift
  args = [:id, :name, :tag_names] if args.empty?
  Url.find_tagged_with(tag).amap(*args)
end

class Array
  def amap(*fields)
    map {|e| fields.map {|field| e.send(field) }}
  end
end