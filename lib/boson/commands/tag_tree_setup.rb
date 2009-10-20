module TagTreeSetup
  def self.after_included
    if Object.const_defined?(:IRB_PROCS)
      IRB_PROCS[:tag_tree_aliases] = lambda { Alias.create :file=>'config/alias.yml'}
      if Object.const_defined?(:Bond)
        IRB_PROCS[:reload_bond] = lambda { ::Readline.completion_proc = ::Bond.agent }
      end
    end

    old_config = ::Hirb.config
    if ::Hirb::View.enabled?
      ::Hirb.disable
      ::Hirb.config_file = 'config/hirb.yml'
      ::Hirb.config(true)
    end
    ::Hirb.enable old_config
  end
end