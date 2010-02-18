class MachineTagTree
  def initialize(query, options={})
    @query, @options = query, options
    if @options[:set_tags_from_tagged]
      @tagged = Url.tagged_with(@query, :include=>:tags)
      @tags = @tagged.map(&:tags).flatten.uniq
    else
      @tags = Tag.machine_tags(@query)
    end
  end

  def namespace_tags
    @namespace_tags ||= @tags.inject({}) {|h,t|
      (h[t.namespace] ||= []) << t; h
    }
  end

  def namespaces
    @namespaces ||= namespace_tags.map {|n,nt|
      Namespace.new(n, nt, :tagged=>@tagged)
    }
  end

  class Namespace
    attr_accessor :tagged, :namespace
    def initialize(namespace, tags, options={})
      @namespace, @tags, @options = namespace, tags, options
      @tagged = @options[:tagged]
    end

    def predicates
      @tags.map(&:predicate)
    end

    def values
      @tags.map(&:value)
    end

    def predicate_map
      @predicate_map ||= @tags.map {|e| [e.predicate, e.value] }.inject({}) {
        |t, (k,v)| (t[k] ||=[]) << v; t
      }
    end

    def tagged_by_branch(pred, value, view)
      current_machine_tag = Tag.build_machine_tag(@namespace, pred,value)
      if @tagged
        @tagged.select {|e| e.tag_list.include?(current_machine_tag) }
      else
        tagged_with_options = (view == :tag_result) ? {:include=>:tags} : {}
        Url.tagged_with(current_machine_tag, tagged_with_options)
      end
    end

    # td: integrate with tagged_by_branch
    def value_count(pred,value)
      Url.tagged_with(Tag.build_machine_tag(@namespace, pred, value)).count
    end

    def pred_count(pred)
      (predicate_map[pred] ||[]).map {|e| [e, value_count(pred, e)]}
    end

    def group_pred_count(pred)
      pred_count(pred).inject({}) {|hash,(k,v)|
        (hash[v] ||= []) << k; hash
      }
    end

    def sort_group_pred_count(pred)
      hash = group_pred_count(pred)
      hash.keys.sort.reverse.map {|e|
        [e, hash[e]]
      }
    end
  end
end