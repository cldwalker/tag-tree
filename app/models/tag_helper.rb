module TagHelper
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval %[
      has_many :nodes, :as=>:objectable
    ]
  end
  
  module ClassMethods
  end
  
end