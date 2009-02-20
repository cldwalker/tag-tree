Node.class_eval %[
  def u; puts self.outline_update; end
]

def ns; Node.nonsemantic_tree; end
def s; Node.semantic_tree; end
def t; Node.tag_tree; end
def t2; Node.find_by_name('tags2'); end

def st(name)
  Node.status(name)
end

def tvo(*args)
  Node.tag_node(args.shift).view_otl(*args)
end

def svo(*args)
  Node.semantic_node(args.shift).view_otl(*args)
end

def sn(name)
  Node.semantic_node(name)
end

def tags(id_or_name)
  node = Node.find_by_id(id_or_name) || Node.find_by_name(id_or_name)
  node.tag_names
end