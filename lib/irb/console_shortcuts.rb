require 'pp'
require 'lib/irb/core_methods'
require 'lib/irb/iam'

begin
  # attempt to load a local alias gem
  require 'local_gem' # gem install cldwalker-local_gem
  LocalGem.local_require 'alias' # gem install cldwalker-alias
rescue LoadError
  require 'alias' # gem install cldwalker-alias
end

module ConsoleMethods; end #defined for alias
Alias.init

ConsoleUpdate.enable_named_scope

begin
  LocalGem.local_require 'hirb'
rescue
  require 'hirb'
end
Hirb::View.enable

#extend delegated methods
self.extend ConsoleMethods
self.extend Hirb::Console
self.extend CoreMethods
self.extend Iam
Iam.register CoreMethods, Hirb::Console, ConsoleMethods