module TagTreeCore
  def self.included(mod)
    require 'namespace_tree'
  end

  # @config :global_options=>true
  # Open urls specified by id in browser
  def open_url(*ourls)
    urls = ourls.map(&:name)
    browser *urls unless urls.empty?
    urls.join(' ')
  end

  # @config :global_options=>true
  # Updates records, looking them up if needed
  def console_update(*ourls)
    ourls.empty? ? [] : Url.console_update(ourls)
  end

  # @config :alias=>'gt'
  # @render_options :fields=>[:id, :old_tags, :new_tags]
  # @options [:save, :S]=>:boolean
  # Renames tags of given urls with gsub
  def gsub_tags(ourls, regex, substitution, options={})
    ourls.map do |e|
      new_tag_list = e.tag_list.map {|f| f.gsub(regex, substitution)}
      if options[:save]
        e.tag_and_save(new_tag_list)
      end
      {:id=>e.id, :old_tags=>e.quick_mode_tag_list, :new_tags=>Url.tag_list(new_tag_list).to_quick_mode_string }
    end
  end

  # @options :pretend=>:boolean
  # Create a url quickly by delimiting fields with ',,'
  def url_create(string, options={})
    name, description, tags = string.split(",,")
    create_hash = {:name=>name}
    if tags.nil?
      create_hash[:tag_list] = description
    else
      create_hash[:description] = description
      create_hash[:tag_list] = tags
    end
    # create_hash[:tag_list] = Url.tag_list(create_hash[:tag_list]).to_a.map {|e| mtag_filter e }.join(',')
    #td: mtag_filter should also replace tags= w/ global predicate=

    options[:pretend] ? create_hash : Url.create(create_hash)
  end

  # @options :or=>{:type=>:boolean, :desc=>'Join queries by OR'}, :limit=>:numeric,
  #   [:conditions,:c]=>{:type=>:string, :desc=>'Sql condition'}, [:offset, :O]=>:numeric
  # @render_options :output_class=>'Url'
  # @config :menu=>{:command=>'browser', :args=>':name'}
  # Find urls by multiple wildcard machine tags. Defaults to AND-ing queries.
  def url_tagged_with(*mtags)
    options = mtags[-1].is_a?(Hash) ? mtags.pop : {}
    mtags.map! {|e| machine_tag_query?(e) ? e : "#{Tag::VALUE_DELIMITER}#{e}" }
    Url.super_tagged_with(mtags, options)
  end

  def machine_tag_query?(word)
    word[/#{Tag::PREDICATE_DELIMITER}|#{Tag::VALUE_DELIMITER}|\./]
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