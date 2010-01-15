module TagAnalysis
  # @config :default_option=>'type'
  # @render_options :change_fields=>['name', 'count']
  # @options :type=>{:type=>:string, :values=>%w{namespace_counts predicate_counts value_counts},
  #  :required=>true, :default=>'namespace_counts'}
  # Lists machine tag counts by machine tag part
  def tag_stats(options={})
    Tag.send(options[:type]).map {|e| [e.counter, e.count.to_i] }
  end

  # @render_options :change_fields=>%w{predicate count}, :sort=>'count', :reverse_sort=>true
  # Lists unique value counts per predicate
  def predicate_value_counts
    Tag.predicates.map {|e|
      [e, unique_predicate_value_tags(e).size]
    }
  end

  # @render_options :change_fields=>['predicate', 'count']
  # List global predicate counts
  def predicate_stats
    DefaultPredicate.global_predicates.map {|e| [e.rule, Url.tagged_with_count("#{e.rule}=")] }
  end

  # Returns most used taggings with id, tag_id and count.
  def tagging_count(options={})
    table = options.delete(:table) || 'tag'
    default_options = {:limit=>20,:group=>"#{table}_id", :select=>"id, taggable_type, #{table}_id, count(*) as count",
     :include=>table, :order=>'count DESC'}
    Tagging.find(:all, default_options.merge!(options))
  end

  # @render_options :change_fields=>['tag', 'count'], :sort=>'count', :reverse_sort=>true
  # @options :limit=>{:type=>:numeric, :bool_default=>true}, :conditions=>:string,
  #  :include=>{:type=>:string, :bool_default=>true}
  # Lists most-used tags by name and count
  def top_tags(options={})
    tagging_count(options).inject({}) do |hash, t|
      hash[t.tag.name] = t.count.to_i
      hash
    end
  end

  # @render_options :fields=>[:id, :name, :count], :sort=>{:default=>:count}, :reverse_sort=>true
  # @options :limit=>{:type=>:numeric, :bool_default=>true}, :conditions=>:string,
  #  :include=>{:type=>:string, :bool_default=>true}
  # Lists most tagged urls
  def top_urls(options={})
    tagging_count(options.merge(:table=>'taggable')).inject([]) do |acc, t|
      acc << {:id=>t.taggable.id, :name=>t.taggable.name, :count=>t.count.to_i}
    end
  end
end