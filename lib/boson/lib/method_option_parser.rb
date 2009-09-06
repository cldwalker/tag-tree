begin
  require 'thor'
rescue LoadError
  puts "Thor gem not found. Though not required, some commands may depend on it. Install with `gem install thor`. "
end
require 'shellwords'

# This class extends functionality from Thor's {Thor::Options class}[http://github.com/wycats/thor/blob/master/lib/thor/options.rb].
# This class provides one main method, MethodOptionParser.parse(). This class adds an enumerated option type which auto aliases known values
# and a symbol option type which allows option values to return as a symbol.
class MethodOptionParser
  class <<self
    # Takes a string or array of arguments and a hash of options expected in those arguments and returns the arguments without the options
    # and the parsed out options.
    # Examples:
    #   MethodOptionParser.parse("some args -v -t a", :verbose=>:boolean, :type=>[:gem, :application, :other] )
    #   => {:verbose=>true, :type=>:application}
    #   MethodOptionParser.parse("some args -t other", :type=>:symbol)
    #   => {:type=>:other}
    def parse(args, options)
      pre_convert_thor_options(options)
      op = Thor::Options.new(options)
      args = Shellwords.shellwords(args) if args.is_a?(String)
      thor_options = op.parse(args)
      parsed_options = post_convert_thor_options(thor_options)
      return op.non_opts, parsed_options
    end

    def pre_convert_thor_options(options)
      @symbol_options = []
      @symbol_keys = []
      @enumerated_options = {}
      options.each do |k,v|
        if k.is_a?(Symbol)
          @symbol_keys << k
        end
    
        if v == :symbol
          @symbol_options << k
          options[k] = :optional
        elsif v.is_a?(Array)
          @enumerated_options[k.to_s] = v
          options[k] = :optional
        end
      end
    end

    def post_convert_thor_options(options)
      #convert frozen Thor::Options::Hash to normal Hash
      parsed_options = Hash.new.update(options)
      parsed_options.each {|k,v|
        parsed_options[k] = v.to_sym if @symbol_options.include?(k)
        if @enumerated_options[k] && (value = @enumerated_options[k].find {|e| e.to_s =~ /^#{v}/ })
          parsed_options[k] = value
        end
        parsed_options[k.to_sym] = parsed_options.delete(k) if @symbol_keys.include?(k.to_sym)
      }
      parsed_options
    end
  end
end