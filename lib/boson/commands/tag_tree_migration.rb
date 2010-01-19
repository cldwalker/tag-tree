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

  # @options :save=>:boolean
  # @desc Detects if urls have a machine tag and if they do, applies the common namespace to
  # remaining normal tags
  def convert_to_machine_tags(ourls, options={})
    namespace = ourls.select {|e|
      nsp = e.tag_list.select {|f| break $1 if f =~ /^(\S+):/}
       break nsp if !nsp.empty?
      false
    }
    if namespace
      ourls.map {|e|
        new_tag_list = e.tag_list.map {|f|
          f.include?("#{namespace}:") ? f : "#{namespace}:#{f}"
        }
        p [e.id, e.tag_list, new_tag_list]
        if options[:save]
          e.tag_and_save(new_tag_list)
        end
      }
    else
      puts "no namespace detected"
    end
    nil
  end
end