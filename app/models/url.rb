class Url < ActiveRecord::Base
  acts_as_taggable_on :tags
  validates_presence_of :name
  validates_uniqueness_of :name
  
  #looks up semantic 
  def self.semantic_tagged_with(*args)
    children = Node.semantic_tree.find_descendant(args[0]).children.map(&:name)
    puts "Including immediate children : #{children.join(',')}" if children.size > 0
    args[0] = children << args[0]
    self.find_tagged_with(*args)
  end
  
  def tag_names; tags.map(&:name); end
end