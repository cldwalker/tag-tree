module TagTreeSetup
  def self.included(mod)
    IRB_PROCS[:tag_tree_aliases] = method(:tag_tree_aliases)
    if Object.const_defined?(:Bond)
      IRB_PROCS[:reload_bond] = lambda { ::Readline.completion_proc = ::Bond.agent }
    end
  end

  def self.safe_local_require(name)
    # attempt to load a local gem
    require 'local_gem'
    LocalGem.local_require name
  rescue LoadError
    require name
  end

  def self.tag_tree_aliases(*args)
    safe_local_require 'alias'

    eval %[ module ::RailsCommands; end ]

    %w{config/alias.yml ~/.alias/rails.yml}.each {|e|
      ::Alias.create :file=>e
    }
    [::RailsCommands].each {|e| self.send :include, e }
    #hacky but works
    ::Boson::Universe.send :include, self
    ::Boson::Universe.send :extend_object, Boson.main_object
  end

  def setup_tag_tree
    IRB_PROCS[:console_update] = lambda { ConsoleUpdate.enable_named_scope }
    load_hirb
  end

  private

  def load_hirb
    old_config = ::Hirb.config
    if ::Hirb::View.enabled?
      ::Hirb.disable
      ::Hirb.config_file = 'config/hirb.yml'
      ::Hirb.config(true)
    end
    ::Hirb.enable old_config
  end
end