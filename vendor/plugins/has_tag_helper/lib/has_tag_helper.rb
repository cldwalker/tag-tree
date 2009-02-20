current_dir = File.dirname(__FILE__)
$:.unshift(current_dir) unless $:.include?(current_dir) || $:.include?(File.expand_path(current_dir))

module HasTagHelper
  def self.included(base) #:nodoc:
    base.extend(ClassMethods)
  end
  
  module ClassMethods
    def has_tag_helper(options={})
      cattr_accessor :default_tagged_class
      self.default_tagged_class = options[:default_tagged_class] if options[:default_tagged_class]
      self.class_eval do
         extend HasTagHelper::SingletonMethods
      end
    end
  end
  
  module SingletonMethods
    # Prints out a list of tags of tags that are used and their current taggings (which should be
    # zero). If called with true ie clean_tags(true), then the unused tags are deleted.
    def clean_tags(clean=false)
      unused = unused_tag_ids
      unused.each {|e|
        e = find(e)
        p [e.name, e.id, e.taggings.size]
      }
      unused.each {|e| destroy(e) } if clean
    end
    
    # Returns the ids of unused tags.
    def unused_tag_ids
      find(:all, :select=>'id').map(&:id) - Tagging.find(:all, :select=>"distinct tag_id").map(&:tag_id)
    end

    def tags_by_type(tagging_type=nil)
      tagging_type ||= self.default_tagged_class
      raise ArgumentError, "Missing a tagging type"
      Tagging.scoped(:conditions=>{:tagging_type=>tagging_type})
    end

    # Returns tag with most counts. By default takes top 20 and uses default_tagged_class if defined.
    def tags_by_count(options={})
      conditions = default_tagged_class ? "taggable_type = '#{default_tagged_class}'" : ''
      Tagging.find(:all, {:conditions=>conditions,:limit=>20,:group=>"tag_id", :select=>"id,tag_id, count(*) as count", :include=>:tag, :order=>'count DESC'}.merge(options))
    end

    # Returns hash of tag names with most tags and their counts.
    def tag_names_to_count(options={})
      hash = {}
      tags_by_count(options).each do |t|
        hash[t.tag.name] = t.count.to_i
      end
      hash
    end
    
    # Returns hash of tag ids and their counts
    def tag_ids_by_count
      hash = {}
      counts = Tagging.find(:all, :group=>"tag_id", :select=>"tag_id, count(*) as count")
      counts.each {|e| hash[e.tag_id] = e.count.to_i}
      hash
    end

    # Given a set of tags, reports tags that are similar by a levenshtein distance.
    def find_similar_words(tags=nil, options={})
      options.reverse_merge!(:distance=>3)
      require 'levenshtein'
      tags ||= find(:all).map(&:name)
      h = {}
      results = []
      tags.each {|e| l = e[0,1]; h[l] ||= []; h[l] << e }
      h.each do |k,v|
        if v.size > 1
          puts "Starting tags starting with '#{k}'"
          v.each_with_index do |a,i|
            v[i+1, v.length-1].each_with_index do |b,j|
              puts "Checking #{a} with #{b}"
              distance = Levenshtein.distance(a, b)
              if (distance < options[:distance])
                puts "Found match: #{a}-#{b}: #{distance}"
                results << [a,b]
              end
            end
          end
        else
          puts "Skipping tags starting with '#{k}'"
        end
      end
      results
    end
    
    # Given a set of tags, returns pairs of tags that are a singular/plural pair.
    def find_plural_pairs(tags=nil)
      tags ||= find(:all).map(&:name)
      results = []
      tags.each {|e| 
        plural = e.pluralize
        if plural != e && tags.delete(plural)
          results << [e,plural]
        end
      }
      results
    end
  end
end
