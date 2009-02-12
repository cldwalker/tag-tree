module TagHelper
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval %[
      has_many :nodes, :as=>:objectable
    ]
  end
  
  module ClassMethods
    def unused_tag_ids
      find(:all, :select=>'id').map(&:id) - Tagging.find(:all, :select=>"distinct tag_id").map(&:tag_id)
    end
  end
  
end