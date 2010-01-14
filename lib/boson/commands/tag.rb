module TagLib
  # Renames tag
  def rename_tag(old_name, new_name)
    Tag.find_by_name(old_name).update_attribute :name, new_name
  end

  # @options :columns=>{:values=>Tag.column_names, :default=>['name']},
  #  :console_update=>:boolean, :limit=>:numeric, :offset=>:numeric
  # @config :render_options=>"Tag"
  # Multiple regexp queries ORed together
  def tag_find(val, options={})
    results = Tag.console_find(val, options)
    Tag.console_update(results) if options[:console_update]
    results
  end

  # @config :default_option=>'type'
  # @render_options :change_fields=>['name', 'count']
  # @options :type=>{:type=>:string, :values=>%w{namespace_counts predicate_counts value_counts},
  #  :required=>true, :default=>'namespace_counts'}
  # Lists machine tag counts by machine tag part
  def tag_stats(options={})
    Tag.send(options[:type]).map {|e| [e.counter, e.count.to_i] }
  end

  # @render_options :change_fields=>['predicate', 'count']
  # List global predicate counts
  def predicate_stats
    DefaultPredicate.global_predicates.map {|e| [e.rule, Url.tagged_with_count("#{e.rule}=")] }
  end

  # @render_options :fields=>{:values=>[:rule, :predicate, :filter, :values, :global],
  #  :default=>[:rule, :predicate, :filter] }, :filters=>{:default=>{:values=>:inspect}}
  # List default predicates
  def default_predicates
    DefaultPredicate.predicates
  end

  # Adds rules to generate default predicates
  def add_rules(*rules)
    DefaultPredicate.add_rules(*rules)
    DefaultPredicate.reload
  end
end