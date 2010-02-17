module UrlFinderCommands
  def self.update_methods
    %w{tag_add_and_remove tag_remove_and_save tag_add_and_save tag_and_save regex_update_attribute}
  end

  def self.config
    {
      :commands=>update_methods.inject({}) {|t,e|
        t[e] = {:args=>[['*uid_and_quick_mtags']], :option_command=>true,
          :config=>{:menu_action=>{:splat=>false}}
        }
        t[e][:args] = [['*args']] if e == 'regex_update_attribute'
        t
      }
    }
  end

  # @config :option_command=>true
  def tag_list(*args)
    ::Url.find(args.shift).tag_list
  end

  generated_methods = update_methods.map do |meth|
    %[
      def #{meth}(uid, *mtags)
        uid = Array(uid)
        ourls = uid[0].is_a?(::Url) ? uid : ::Url.find(uid)
        ourls.each {|e| e.#{meth}(*mtags) }
      end
    ]
  end.join("\n")
  module_eval generated_methods
end
