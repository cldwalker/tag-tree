module TagTreeSetup
  def self.included(mod)
    IRB_PROCS[:tag_tree_aliases] = lambda { Alias.create :file=>'config/alias.yml'}
    if Object.const_defined?(:Bond)
      IRB_PROCS[:reload_bond] = lambda { ::Readline.completion_proc = ::Bond.agent }
    end
  end

  def setup_tag_tree
    old_config = ::Hirb.config
    if ::Hirb::View.enabled?
      ::Hirb.disable
      ::Hirb.config_file = 'config/hirb.yml'
      ::Hirb.config(true)
    end
    ::Hirb.enable old_config
  end
end