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

def tn(name)
  Tag.find_by_name(name.to_s)
end

def change_tag(old_name, new_name)
  Tag.find_by_name(old_name).update_attribute :name, new_name
end

#open url object id
def o(*url_ids)
  urls = url_ids.map {|e| Url.find_by_id(e)}.compact.map {|e| "'#{e.name}'"}
  system("open " + urls.join(" "))
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
  pp Url.find_tagged_with(tag).amap(*args)
end

def uc(string)
  Url.quick_create(string)
end

def urn(string)
  Url.find_name_by_regexp(string)
end

def qg(*args)
  QueryGroup.new(*args)
end

def tg(*args)
  TagGroup.new(*args)
end

def ng(*args)
  NamespaceGroup.new(*args)
end
