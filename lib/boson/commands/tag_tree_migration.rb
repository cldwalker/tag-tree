# used when migrating from tags to machine tags
module TagTreeMigration
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
    Url.find_and_regex_change_tags(args[0], /^/, args[2] || 'site:', {:save=>args[1] || false})
  end

  def pconvert(*args)
    Url.find_and_change_machine_tags(*(args << {:save=>true}))
  end
end