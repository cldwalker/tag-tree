class Tag < ActiveRecord::Base
  # has_many :nodes, :as=>:objectable
  has_tag_helper :default_tagged_class=>"Url"
  def self.hello; 'hello dude'; end
end
