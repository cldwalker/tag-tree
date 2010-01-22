module UrlFinderCommands
  def self.url_methods
     %w{tag_list regex_update_attribute tag_and_save}
  end

  def self.implicit_tag_methods
    %w{tag_add_and_remove tag_remove_and_save tag_add_and_save}
  end

  def self.config
    { :commands=>(url_methods + implicit_tag_methods).inject({}) {|t,e|
        t[e] = {:args=>[['*uid_and_quick_mtags']], :option_command=>true}; t
      }
    }
  end

  generated_methods = url_methods.map do |meth|
    %[
      def #{meth}(uid, *args)
        ::Url.find(uid).#{meth}(*args)
      end
    ]
  end.join("\n") +
  implicit_tag_methods.map do |meth|
    %[
      def #{meth}(uid, *mtags)
        ourl = uid.is_a?(::Url) ? uid : ::Url.find(uid)
        # mtags.map! {|e| implicit_tag_filter(e, ourl) }
        ourl.#{meth}(*mtags)
      end
    ]
  end.join("\n")
  module_eval generated_methods
end
