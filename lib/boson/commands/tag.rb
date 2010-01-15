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

  # Find tag names within machine tag fields with regex string
  def search_machine_tag_names(name='')
    Tag.machine_tag_names.grep(/#{name}/)
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

  # @render_options :change_fields=>['tag', 'count']
  # Lists values of global predicates that conflict. Depends on external core/array library
  def check_global_predicates
    vals = DefaultPredicate.global_predicates.map {|e| e.values}.flatten
    count_hash(vals).select {|k,v| v > 1 }
  end

  # Prints out a list of unused tags to destroy
  def check_unused_tags(options={})
    unused = unused_tag_ids
    return unused if unused.empty?
    menu(Tag.find(unused), :fields=>[:name, :id, :taggings_size]) do |chosen|
      chosen.each {|e| Tag.destroy(e) }
    end
  end

  private
  # Prints out a list of tags of tags that are used and their current taggings (which should be
  # Returns the ids of unused tags.
  def unused_tag_ids
    Tag.find(:all, :select=>'id').map(&:id) - Tagging.find(:all, :select=>"distinct tag_id").map(&:tag_id)
  end
end