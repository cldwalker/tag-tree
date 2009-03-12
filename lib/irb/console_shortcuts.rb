require 'pp'
# require 'irb/table'
require 'irb/method_option_parser'
# used for extending the main irb object
module ConsoleMethods; end

begin
  # attempt to load a local alias gem
  require 'local_gem' # gem install cldwalker-local_gem
  LocalGem.local_require 'alias' # gem install cldwalker-alias
rescue LoadError
  require 'alias' # gem install cldwalker-alias
end
Alias.init
#extend delegated methods
self.extend ConsoleMethods

ConsoleUpdate.enable_named_scope

begin
  LocalGem.local_require 'hirb'
rescue
  require 'hirb'
end
Hirb::View.enable

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