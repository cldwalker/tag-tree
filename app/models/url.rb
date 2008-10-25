class Url < ActiveRecord::Base
  acts_as_taggable_on :tags
  validates_presence_of :name
  validates_uniqueness_of :name
end