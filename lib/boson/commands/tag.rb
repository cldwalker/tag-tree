module TagLib
  # Renames tag
  def rename_tag(old_name, new_name)
    Tag.find_by_name(old_name).update_attribute :name, new_name
  end

  # @options :columns=>{:values=>%w{id name description created_at namespace predicate value}, :default=>['name']},
  #  :console_update=>:boolean
  # Multiple regexp queries ORed together
  def tag_query(val, options={})
    results = Tag.find_by_regexp(val, options[:columns])
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
end