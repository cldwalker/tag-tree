module UrlFinderCommands
  # console_update depends on cldwalker-console_update gem
  url_methods = %w{tag_add_and_remove tag_remove_and_save tag_add_and_save tag_list console_update tag_and_save}
  generated_methods = url_methods.map do |m|
      %[
        def #{m}(finder, *args)
        ::Url.find(finder).#{m}(*args)
        end
      ]
  end.join("\n")
  module_eval generated_methods
end
