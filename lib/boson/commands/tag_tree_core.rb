module TagTreeCore
  def self.included(mod)
    require 'namespace_tree'
  end

  def rename_tag(old_name, new_name)
    Tag.find_by_name(old_name).update_attribute :name, new_name
  end

  #open url object id
  def open_url(*args)
    urls = Url.console_find(args).map(&:name)
    system(*(['open'] + urls))
  end

  def clip_url(*args)
    to_copy = Url.console_find(args).map(&:name).join(" ")
    IO.popen('pbcopy', 'w+') {|e| e.write(to_copy) }
  end

  #options :view=>{:type=>:string, :values=>NamespaceTree::VIEWS}
  def query_tree(mtag, options={})
    QueryTree.new(mtag, options)
  end

  #options :view=>{:type=>:string, :values=>NamespaceTree::VIEWS}
  # Displays different tag trees given a wildcard machine tag
  def tag_tree(mtag, options={})
    TagTree.new(mtag, options)
  end

  #options :view=>{:type=>:string, :values=>NamespaceTree::VIEWS}
  def namespace_tree(mtag, options={})
    NamespaceTree.new(mtag, options)
  end
end