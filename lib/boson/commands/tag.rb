module TagLib
  # Renames tag
  def rename_tag(old_name, new_name)
    Tag.find_by_name(old_name).update_attribute :name, new_name
  end

  # Updates regex of tags with console_update
  def tag_console_update(name)
    Tag.find_name_by_regexp(name).console_update
  end

  # @config :default_option=>'type'
  # @render_options :change_fields=>{:default=>{0=>'name', 1=>'count'}}
  # @options :type=>{:type=>:string, :values=>%w{namespace_counts predicate_counts value_counts},
  #  :required=>true, :default=>'namespace_counts'}
  # Lists machine tag counts by machine tag part
  def tag_stats(options={})
    Tag.send(options[:type]).map {|e| [e.counter, e.count.to_i] }
  end
end