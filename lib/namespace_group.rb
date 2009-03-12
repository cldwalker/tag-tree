# These classes are used for querying machine tags and grouping results as outlines.
# These methods are for console use and may change quickly.
class NamespaceGroup #:nodoc:
  def initialize(name, options={})
    @name = name.to_s
    @options = options
    @tags = options[:tags] if options[:tags]
  end

  def tags
    @tags ||= Tag.find_all_by_namespace(@name)
  end

  def predicates
    tags.map(&:predicate)
  end

  def values
    tags.map(&:value)
  end

  def predicate_map
    tags.map {|e| [e.predicate, e.value] }.inject({}) {
      |t, (k,v)| (t[k] ||=[]) << v; t
    }
  end
  alias :pm :predicate_map

  def value_count(pred,value)
    Url.tagged_with(Tag.build_machine_tag(@name, pred, value)).count
  end

  def pred_count(pred)
    (predicate_map[pred] ||[]).map {|e| [e, value_count(pred, e)]}
  end

  def group_pred_count(pred)
    pred_count(pred).inject({}) {|hash,(k,v)|
      (hash[v] ||= []) << k
      hash
    }
  end
  
  def sort_group_pred_count(pred)
    hash = group_pred_count(pred)
    hash.keys.sort.reverse.map {|e|
      [e, hash[e]]
    }
  end
  
  def predicate_view(pred, view=nil)
    if view == :group
      sort_group_pred_count(pred).map {|k,v|
        "#{k}: #{v.join(', ')}"
      }
    elsif view == :count
      pred_count(pred).map {|k,v|
        "#{k}: #{v}"
      }
    else
      nil
    end
  end
  
  def tagged_items_per_node(tagged_items, pred, value, view_type)
    current_machine_tag = Tag.build_machine_tag(@name, pred,value)
    tagged_items.select {|e| 
      e.tag_list.include?(current_machine_tag)
    }
  end
  
  def results_per_node(pred, value, view_type)
    if @options[:tagged_items]
      tagged_items_per_node(@options[:tagged_items], pred, value, view_type)
    else
      tagged_with_options = view_type == :tag_result ? {:include=>:tags} : {}
      Url.tagged_with(Tag.build_machine_tag(@name, pred, value), tagged_with_options)
    end
  end
  
  def result_view(pred, value, view_type)
    if [:description_result, :result, :tag_result].include?(view_type)
      urls = self.results_per_node(pred, value, view_type)
      urls.map {|u|
        string = format_result(u)
        string += " : #{u.description}" if view_type == :description_result
        string += " : #{u.tag_list}" if view_type == :tag_result
        string
      }
    else
      []
    end
  end
  
  def outline_view(type=nil)
    body = [@name]
    level_delim = "\t"
    predicate_map.each do |pred, vals|
      body << [level_delim + pred]
      values = predicate_view(pred, type) || vals
      values.each {|e|
          value_string = level_delim * 2 + e
          value_string += ": #{Tag.machine_tag(@name, pred, e).description}" if type == :value_description
          body << value_string
          body += result_view(pred, e, type).map {|e| level_delim * 3 + e}
      }
    end
    body.join("\n")
  end
  
  def format_result(result)
    "#{result.id}: #{result.name}"
  end

  def inspect
    outline_view(@options[:view])
  end
  
  def duplicate_values
    array_duplicates(values)
  end
  
  def array_duplicates(array)
      hash = array.inject({}) {|h,e|
        h[e] ||= 0
        h[e] += 1
        h
      }
      hash.delete_if {|k,v| v<=1}
      hash.keys
  end
  
end

class TagGroup < NamespaceGroup #:nodoc:
  def namespaces
    tags.map(&:namespace).uniq
  end
  
  def outline_view(type=nil)
    "\n" + namespace_groups.map {|e| e.outline_view(type) }.join("\n")
  end
  
  def inspect; super; end
  
  def namespace_tags
    tags.inject({}) {|h,t|
      (h[t.namespace] ||= []) << t
      h
    }
  end
  
  def namespace_groups
    unless @namespace_groups
      @namespace_groups = namespace_tags.map {|name, tags|
        NamespaceGroup.new(name, :tags=>tags)
      }
    end
    @namespace_groups
  end
  
  def tags
    @tags ||= Tag.machine_tags(@name)
  end
end

class QueryGroup < TagGroup #:nodoc:
  def namespace_groups
    unless @namespace_groups
      @namespace_groups = namespace_tags.map {|name, tags|
        NamespaceGroup.new(name, :tags=>tags, :tagged_items=>tagged_items)
      }
    end
    @namespace_groups
  end
  
  #same as taggables
  def tagged_items
    @tagged_items ||= Url.tagged_with(@name, :include=>:tags)
  end
  
  def tags
    @tags ||= tagged_items.map(&:tags).flatten.uniq
  end
end