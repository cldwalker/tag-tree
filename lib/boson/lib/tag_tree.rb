class TagTree < Hirb::Helpers::Tree
  VIEWS = [:result, :group, :count, :description_result, :tag_result, :value_description, :table, :basic]
  FIELDS = [:id, :name, :description, :quick_mode_tag_list]

  class <<self
  def render(mtree, options={})
    @options = options
    @view = options[:view] || :basic
    nodes = build_mtree_nodes(mtree)
    super(nodes, options)
  end

  def build_mtree_nodes(mtree)
    mtree.namespaces.inject([]) {|t,e| t + build_namespace_nodes(e) }
  end

  def build_namespace_nodes(nsp)
    @nsp = nsp
    tree = [[0, nsp.namespace]]
    @nsp.predicate_map.each do |pred, vals|
      tree << [1, pred]
      tree += build_predicate_branches(pred, vals)
    end
    tree
  end

  def build_predicate_branches(pred, values)
    branches = []
    if (groups = group_predicates(pred))
      groups.each {|e| branches << [2, e] }
    else
      values.each {|val|
        val_node = val.dup
        val_node += ": #{Tag.machine_tag(@nsp.namespace, pred, val).description}" if @view == :value_description
        branches << [2, val_node]
        branches += build_results(pred, val)
      }
    end
    branches
  end

  def group_predicates(pred)
    if @view == :group
      @nsp.sort_group_pred_count(pred).map {|k,v|
        "#{k}: #{v.join(', ')}"
      }
    elsif @view == :count
      @nsp.pred_count(pred).map {|k,v|
        "#{k}: #{v}"
      }
    end
  end

  def build_results(pred, val)
    results = @nsp.tagged_by_branch(pred, val, @view) unless @view == :basic
    if @view == :table
      tree_indent = 4 # must match tree helper indent
      table = Hirb::Helpers::AutoTable.render(results, :fields=>@options[:fields],
        :description=>false, :headers=>false, :max_width=>Hirb::View.width - 3 * tree_indent)
      [[3, table]]
    elsif [:description_result, :result, :tag_result].include?(@view)
      format_results(results).map {|f| [3, f] }
    else
      []
    end
  end

  def format_results(results)
    results.map {|e|
      string = "#{e.id}: #{e.name}"
      string += " : #{e.description}" if @view == :description_result
      string += " : #{e.tag_list}" if @view == :tag_result
      string
    }
  end
  end
end