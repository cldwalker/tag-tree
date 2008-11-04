#this file contains handy methods and aliases to be used from the console
require 'pp'

U = Url
Tr = Tree
T = Tag
N = Node

ActiveRecord::Base.class_eval %[
  alias_method :ua, :update_attribute  
  class<<self
    alias_method :f, :find
    alias_method :d, :destroy
  end
  def self.fn(*args); self.find_by_name(*args); end
]

Url.class_eval %[
  alias_method :t, :tag_and_save
  class<<self
    alias_method :us, :used_but_not_semantic
    alias_method :ut, :used_to_tag
    alias_method :tr, :tags_related
    alias_method :ftw, :find_tagged_with
    alias_method :stw, :semantic_tagged_with
  end
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

#open url object id
def o(*url_ids)
  urls = url_ids.map {|e| Url.find_by_id(e)}.compact.map {|e| "'#{e.name}'"}
  system("open " + urls.join(" "))
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