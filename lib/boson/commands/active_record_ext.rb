module ::ConsoleExtensions
  def self.included(base)
    base.class_eval %[
      named_scope :find_by_regexp, lambda {|query,fields|
        conditions = fields.map {|f| "#\{f} REGEXP ?" }.join(" OR ")
        {:conditions=>[conditions, *Array.new(fields.size, query) ]}
      }
    ]
  end
end

module ActiveRecordExt
  def self.config
    {:dependencies=>['start_rails']}
  end

  def self.after_included
    if Object.const_defined?(:IRB_PROCS)
      IRB_PROCS[:ar_extensions] = method(:ar_extensions)
    else
      ar_extensions
    end
  end

  def self.ar_extensions(*args)
    ::ActiveRecord::Base.class_eval %[
      class<<self
        def inherited(child)
          super
          child.class_eval do
            include ::ConsoleExtensions
          end
        end

        alias_method :f, :find
      end

      def rua(name, value)
        require 'abbrev'
        if name = self.class.column_names.abbrev[name.to_s]
          update_attribute(name, value)
        else
          puts "'\#{name}' doesn't match a column"
        end
      end
    ]
    #since Tag was already defined by gems
    ::Tag.class_eval %[include ::ConsoleExtensions]
    ::Url.class_eval %[include ::ConsoleExtensions]
  end
end
