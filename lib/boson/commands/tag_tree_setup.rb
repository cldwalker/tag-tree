module TagTreeSetup
  def self.after_included
    if Object.const_defined?(:IRB_PROCS)
      IRB_PROCS[:tag_tree_aliases] = lambda {|e| Alias.create :file=>'config/alias.yml'}
      if $".include?('bond.rb')
        IRB_PROCS[:reload_bond] = lambda {|e| ::Readline.completion_proc = ::Bond.agent }
      end
    end
  end
end