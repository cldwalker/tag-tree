module ::ConsoleExtensions
  def self.included(base)
    base.class_eval %[
      scope :find_by_regexp, lambda {|query,fields|
        conditions = fields.map {|f| "#\{f} ~* ?" }.join(" OR ")
        {:conditions=>[conditions, *Array.new(fields.size, query) ]}
      }

      def self.console_find(*queries)
        options = queries[-1].is_a?(Hash) ? queries.pop : {}
        queries = queries[0].to_a if queries[0].is_a?(Range)
        if queries[0].is_a?(Integer)
          results = queries.map {|e| find(e) rescue nil }.compact
        else
          results = queries[0] ? find_by_regexp(queries[0], options[:columns] || ['name']).
            find(:all, options.slice(:limit, :offset, :conditions)) :
            find(:all, options.slice(:limit, :offset, :conditions))
        end
        results
      end
    ]
  end
end

module ActiveRecordExt
  def self.config
    {:dependencies=>['start_app']}
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

      def regex_update_attribute(field, value)
        if name = self.class.column_names.sort.find {|e| e[/^\#{field}/] }
          update_attribute(name, value)
        else
          puts "'\#{field}' doesn't match a column"
        end
      end
    ]
    #since Tag was already defined by gems
    ::Tag.class_eval %[include ::ConsoleExtensions]
    ::Url.class_eval %[include ::ConsoleExtensions]
  end
end
