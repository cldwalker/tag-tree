require 'irb/method_option_parser'

module CoreMethods
  def change_tag(old_name, new_name)
    Tag.find_by_name(old_name).update_attribute :name, new_name
  end

  #open url object id
  def o(*args)
    urls = Url.console_find(args).map(&:name)
    system(*(['open'] + urls))
  end

  def ucp(*args)
    to_copy = Url.console_find(args).map(&:name).join(" ")
    IO.popen('pbcopy', 'w+') {|e| e.write(to_copy) }
  end

  #url-paged
  def up(offset=nil, limit=20)
    columns = [:id, :name, :quick_mode_tag_list]
    #only set if an offset is given
    if offset
      @results = Url.find(:all, :offset=>offset, :limit=>limit)
    end
    @results
  end

  def generate_config
    values = {}
    Tag.find(:all, :conditions=>"namespace NOT NULL").map {|e|
      values[e.value] ||= {}
      values[e.value][e.namespace]
    }
  end

  def fix_config
    Tag.values.map {|e|
      [e, Tag.find_all_by_value(e).map(&:predicate)]
    }.select {|e| e[1].include?('tags')}
  end

  def convert(*args)
    Url.find_and_change_machine_tags(*(args << {:save=>true}))
  end

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

  def qg(*args)
    args = parse_query_options(args)
    QueryGroup.new(*args)
  end

  def tg(*args)
    args = parse_query_options(args)
    TagGroup.new(*args)
  end

  def ng(*args)
    args = parse_query_options(args)
    NamespaceGroup.new(*args)
  end
end