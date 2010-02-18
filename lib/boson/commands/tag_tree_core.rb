module TagTreeCore
  def self.included(mod)
    require 'tag_tree'
    require 'machine_tag_tree'
  end

  # @config :option_command=>true
  # Open urls specified by id in browser
  def open_url(*ourls)
    urls = ourls.map(&:name)
    browser *urls unless urls.empty?
    urls.join(' ')
  end

  # @config :option_command=>true
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

  # @config :option_command=>true
  # Create a url object quickly. Third arguments and on are used for optional description.
  def url_create(url, quick_mtags, *desc)
    create_hash = {:name=>url, :tag_list=>quick_mtags}
    create_hash[:description] = desc.join(' ') unless desc.empty?
    Url.create(create_hash)
  end

  # @options :or=>{:type=>:boolean, :desc=>'Join queries by OR'}, :limit=>:numeric,
  #   [:conditions,:c]=>{:type=>:string, :desc=>'Sql condition'}, [:offset, :O]=>:numeric
  # @render_options :output_class=>'Url'
  # @config :menu=>{:command=>'browser', :default_field=>:name}
  # Find urls by multiple wildcard machine tags. Defaults to AND-ing queries.
  def url_tagged_with(*mtags)
    options = mtags[-1].is_a?(Hash) ? mtags.pop : {}
    mtags.map! {|e| MachineTag.query?(e) ? e : "#{Tag::VALUE_DELIMITER}#{e}" }
    Url.super_tagged_with(mtags, options)
  end

  # @render_options :class=>TagTree, [:view, :w]=>{:type=>:string, :values=>TagTree::VIEWS, :default=>:table},
  #  :fields=>TagTree::FIELDS, :multi_line_nodes=>true
  # @options [:set_tags_from_tagged,:t]=>:boolean
  # Display different tag trees given machine tag wildcard
  def machine_tag_tree(mtag, options={})
    MachineTagTree.new(mtag, options)
  end
end