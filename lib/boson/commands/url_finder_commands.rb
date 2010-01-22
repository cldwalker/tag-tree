module UrlFinderCommands
  def self.url_methods
     %w{tag_list regex_update_attribute tag_and_save}
  end

  def self.implicit_tag_methods
    %w{tag_add_and_remove tag_remove_and_save tag_add_and_save}
  end

  def self.config
    { :commands=>(url_methods + implicit_tag_methods).inject({}) {|t,e|
        # t[e] = {:args=>[['uid'], ['*implicit_tags']], :option_command=>true}; t
        t[e] = {:args=>'*'}; t
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
        ourl = ::Url.find(uid)
        mtags.map! {|e| implicit_tag_filter(e, ourl) }
        ourl.#{meth}(*mtags)
      end
    ]
  end.join("\n")
  module_eval generated_methods

  # Filters machine tag list with namespace and quick_mtags filters
  def implicit_tag_filter(mtag, ourl)
    call_filter(:quick_mtags, add_namespace_filter(mtag, ourl))
  end

  # Adds primary namespace from a url if a machine tag has no namespace
  def add_namespace_filter(mtag, ourl)
    mtag[/#{Tag::PREDICATE_DELIMITER}/] ? mtag : ourl.tag_list.primary_namespace.to_s + Tag::PREDICATE_DELIMITER + mtag
  end
end
