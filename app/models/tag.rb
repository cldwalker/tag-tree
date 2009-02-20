class Tag < ActiveRecord::Base
  has_tag_helper :default_tagged_class=>"Url"
end
