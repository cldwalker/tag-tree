module TagLib
  # @options :exact=>:boolean
  # Renames tag(s)
  def rename_tags(old_name, new_name, options={})
    if options[:exact]
      Tag.find_by_name(old_name).update_attribute :name, new_name
    else
      old_name, new_name = mtag_filter(old_name), mtag_filter(new_name)
      Tag.console_find(old_name +'$').each {|e| e.update_attribute :name, e.name.gsub(/#{old_name}$/, new_name) }
    end
  end

  # @render_options :output_class=>"Tag"
  # @options :columns=>{:values=>Tag.column_names, :default=>['name']},
  #  :console_update=>:boolean, :limit=>:numeric, :offset=>:numeric
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

  # @render_options :output_class=>'DefaultPredicate', :fields=>{:values=>[:rule, :predicate, :filter, :values, :global]}
  # List default predicates
  def default_predicates
    DefaultPredicate.predicates
  end

  # Adds rules to generate default predicates
  def add_rules(*rules)
    DefaultPredicate.add_rules(*rules)
    DefaultPredicate.reload
  end

  # @config :alias=>'pvs'
  # @desc Lists values of given predicates. If predicate doesn't exist then it's looked up.
  # If no predicates given, lists all predicate values
  def predicate_values(*preds)
    if !preds.empty?
      preds.map {|pred|
        dpred = DefaultPredicate.global_predicates.find {|e| e.predicate == pred }
        dpred ? dpred.values : unique_predicate_value_tags(pred).map {|e| e.value }.flatten
      }.flatten
    else
      DefaultPredicate.global_predicates.map {|e| e.values}.flatten
    end
  end

  # Lists tags with unique values per predicate
  def unique_predicate_value_tags(pred)
    Tag.find(:all, :conditions=>{:predicate=>pred}, :select=>'distinct value, predicate')
  end

  # @render_options :change_fields=>['tag', 'count']
  # Lists values of global predicates that conflict across predicates. Depends on external core/array library
  def check_unique_values
    vals = DefaultPredicate.global_predicates.map {|e| e.values}.flatten
    count_hash(vals).select {|k,v| v > 1 }
  end

  # @render_options :fields=>[:value, :expected, :actual]
  # List values of global predicates that aren't faithful to just one predicate
  def check_faithful_values
    DefaultPredicate.global_predicates.inject([]) do |acc, pred|
      pred.values.each do |value|
        unique_pred_values = Tag.find(:all, :conditions=>{:value=>value}, :select=>'distinct predicate, value')
        if unique_pred_values.size > 1
          acc << {:value=>value, :expected=>pred.predicate, :actual=>unique_pred_values.map {|e| e.predicate }}
        end
      end
      acc
    end
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