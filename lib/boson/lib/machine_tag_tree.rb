class MachineTagTree
  def self.tagged_count(query, options={})
    new(query, options).tagged_count
  end

  def initialize(query, options={})
    if options[:set_tags_from_tagged]
      @tagged = Url.tagged_with(query, :include=>:tags)
      @tags = @tagged.map(&:tags).flatten.uniq
    elsif options[:regexp_tags]
      @tags = Tag.find_by_regexp(query, ['name'])
    else
      @tags = Tag.machine_tags(query)
    end
    [:namespace, :predicate, :value].each {|field|
      if options[field]
        @tags = @tags.select {|e| options[field].include?(e.send(field)) }
      end
    }
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

  def tagged_count
    namespaces.inject([]) {|rows,nsp|
      nsp.predicates.each {|pred|
        row = {:namespace=>nsp.namespace, :predicate=>pred}
        nsp.pred_count(pred).each do |val, count|
          rows << row.merge(:value=>val, :count=>count)
        end
      }
      rows
    }
  end

  class Namespace
    attr_accessor :tagged, :namespace
    def initialize(namespace, tags, options={})
      @namespace, @tags, @options = namespace, tags, options
      @tagged = @options[:tagged]
    end

    def predicates
      @tags.map(&:predicate).uniq
    end

    def values
      @tags.map(&:value).uniq
    end

    def predicate_map
      @predicate_map ||= @tags.map {|e| [e.predicate, e.value] }.inject({}) {
        |t, (k,v)| (t[k] ||=[]) << v; t
      }
    end

    def tagged_by_branch(pred, value, view)
      if @tagged
        tagged_with(pred, value)
      else
        tagged_with_options = [:tag_result, :table].include?(view) ? {:include=>:tags} : {}
        Url.tagged_with(machine_tag(pred, value), tagged_with_options)
      end
    end

    def tagged_with(pred, value)
      @tagged.select {|e| e.tag_list.include?(machine_tag(pred, value)) }
    end

    def machine_tag(pred, value)
      Tag.build_machine_tag(@namespace, pred,value)
    end

    def value_count(pred, value)
      @tagged ? tagged_with(pred, value).size : Url.tagged_with(machine_tag(pred, value)).count
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