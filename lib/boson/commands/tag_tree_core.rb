module TagTreeCore
  def self.included(mod)
    require 'namespace_tree'
  end

  # @config :global_options=>true
  # Open urls specified by id in browser
  def open_url(*args)
    urls = Url.console_find(*args).map(&:name)
    browser *urls unless urls.empty?
    urls.join(' ')
  end

  # @render_options :fields=>[:id, :old_tags, :new_tags]
  # @options [:save, :S]=>:boolean
  # Renames tags of given urls with gsub
  def gsub_tags(urls, regex, substitution, options={})
    urls.map do |e|
      new_tag_list = e.tag_list.map {|f| f.gsub(regex, substitution)}
      if options[:save]
        e.tag_and_save(new_tag_list)
      end
      {:id=>e.id, :old_tags=>e.tag_list, :new_tags=>new_tag_list.join(', ')}
    end
  end

  # @options :view=>{:type=>:string, :values=>NamespaceTree::VIEWS}
  # Displays query tree given wildcard machine tag
  def query_tree(mtag, options={})
    QueryTree.new(mtag, options)
  end

  # @render_options :output_class=>NamespaceTree'
  # @options :view=>{:type=>:string, :values=>NamespaceTree::VIEWS}
  # Displays different tag trees given a wildcard machine tag
  def tag_tree(mtag, options={})
    TagTree.new(mtag, options)
  end

  # @options :view=>{:type=>:string, :values=>NamespaceTree::VIEWS}
  # Displays namespace tree given wildcard machine tag
  def namespace_tree(mtag, options={})
    NamespaceTree.new(mtag, options)
  end
end