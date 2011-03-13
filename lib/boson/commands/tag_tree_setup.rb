module TagTreeSetup
  def self.after_included
    if Object.const_defined?(:IRB_PROCS)
      if $".include?('bond.rb')
        IRB_PROCS[:reload_bond] = lambda { ::Readline.completion_proc = ::Bond.agent }
      end
    end
  end
end
