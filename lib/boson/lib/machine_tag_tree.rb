class MachineTagTree
  def self.tagged_count(query, options={})
    new(query, options).tagged_count
  end

  def initialize(query, options={})
    @options = options

    if options[:set_tags_from_tagged]
      @tagged = tagged_with(query, :include=>:tags)
      @tags = @tagged.map(&:tags).flatten.uniq
    elsif options[:regexp_tags]
      @tags = Tag.find_by_regexp(query, ['name'])
    else
      @tags = Tag.machine_tags(query)
    end
    [:namespace, :predicate, :value].each {|field|
      if options[field]
        possible_matches = options[field].split(',')
        @tags = @tags.select {|e|
          field_value = e.send(field)
          possible_matches.any? {|m| field_value =~ /^#{m}/ }
        }
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
      Namespace.new(n, nt, :tree=>self)
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

  def tagged_by_branch(mtag, options={})
    if @tagged
      cache_tagged_with(mtag)
    else
      tagged_with mtag, options
    end
  end

  def tagged_with(mtag, options={})
    results = Url.tagged_with(mtag, options)
    @options[:context] ? filter_tagged(results, @options[:context]) : results
  end

  def filter_tagged(tagged, filter)
    tagged.select {|e| e.tag_list.any? {|t| t =~ /#{filter}/ } }
  end

  def tagged_by_branch_count(mtag)
    @tagged ? cache_tagged_with(mtag).size : @options[:context] ?
      tagged_with(mtag).size : Url.tagged_with(mtag).count
  end

  def cache_tagged_with(mtag)
    @tagged.select {|e| e.tag_list.include?(mtag) }
  end

  class Namespace
    attr_accessor :tagged, :namespace
    def initialize(namespace, tags, options={})
      @namespace, @tags, @options = namespace, tags, options
      @tree = @options[:tree]
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
      @tree.tagged_by_branch(Tag.build_machine_tag(@namespace, pred,value),
        [:tag_result, :table].include?(view) ? {:include=>:tags} : {})
    end

    def value_count(pred, value)
      @tree.tagged_by_branch_count Tag.build_machine_tag(@namespace, pred,value)
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