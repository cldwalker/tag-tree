module TagTreeCore
  def self.included(mod)
    require 'method_option_parser'
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

  def query_tree(*args)
    args = parse_query_options(args)
    QueryTree.new(*args)
  end

  def tag_tree(*args)
    args = parse_query_options(args)
    TagTree.new(*args)
  end

  def namespace_tree(*args)
    args = parse_query_options(args)
    NamespaceTree.new(*args)
  end

  private
  def parse_method_options(args, options)
    MethodOptionParser.parse(args, options)
  end

  def parse_query_options(args)
    if args.size == 1
      args, options = parse_method_options(args[0], :view=>[:result, :group, :count, :description_result, :tag_result, :value_description])
      args << options
    end
    args
  end
end