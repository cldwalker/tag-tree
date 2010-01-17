module UrlFinderCommands
  url_methods = %w{tag_add_and_remove tag_remove_and_save tag_add_and_save tag_list} +
    %w{regex_update_attribute tag_and_save}
  generated_methods = url_methods.map do |m|
      %[
        def #{m}(finder, *args)
        ::Url.find(finder).#{m}(*args)
        end
      ]
  end.join("\n")
  module_eval generated_methods
end
