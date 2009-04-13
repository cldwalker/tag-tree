require 'pp'
# used with alias
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
self.extend Hirb::Console

require 'lib/irb/core_methods'
self.extend CoreMethods