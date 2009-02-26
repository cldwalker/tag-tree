begin
  # attempt to load a local alias gem
  require 'local_gem' # gem install cldwalker-local_gem
  LocalGem.local_require 'alias' # gem install cldwalker-alias
rescue LoadError
  require 'alias' # gem install cldwalker-alias
end
Alias.init

def trn(name)
  Tag.find_name_by_regexp(name.to_s)
end

def mtrn(name)
  Tag.search_machine_tag_names(name)
end

def tn(name)
  Tag.find_by_name(name.to_s)
end

def change_tag(old_name, new_name)
  Tag.find_by_name(old_name).update_attribute :name, new_name
end

#open url object id
def o(*args)
  if args[0].is_a?(Integer)
    results = args.map {|e| Url.find_by_id(e)}
  else
    results = Url.tagged_with(*args)
  end
  urls = results.compact.map(&:name)
  system(*(['open'] + urls))
end

def tl(*ids)
  ids.map {|e| [e, Url.find(e).tag_list ] }
end

#url-paged
def up(offset=nil, limit=20)
  columns = [:id, :name, :tag_list]
  #only set if an offset is given
  if offset
    @url_results = uf(offset, limit).amap(*columns)
  end
  pp @url_results
end

#url-find
def uf(offset=0, limit=20)
  Url.find(:all, :offset=>offset, :limit=>limit)
end

#urls-tagged, already formatted
def ut(*args)
  tag = args.shift
  args = [:id, :name, :tag_list] if args.empty?
  results = tag.split(/\s*\+\s*/).map {|e| Url.tagged_with(e) }
  results = results.size > 1 ? results.inject {|t,v| t & v } : results.flatten
  pp results.amap(*args)
end

def uc(string)
  Url.quick_create(string)
end

def urn(string)
  Url.find_name_by_regexp(string)
end

def convert(*args)
  Url.find_and_change_machine_tags(args.map {|e| Url.find(e)}, :save=>true)
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