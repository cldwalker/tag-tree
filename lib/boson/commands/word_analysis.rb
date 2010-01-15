module WordAnalysis
  # @render_options :change_fields=>%w{word plural}
  # Given a set of tag names, lists pairs of tags that are a singular/plural pair.
  def find_plurals(tags=nil)
    tags ||= Tag.machine_tag_names
    results = []
    tags.each {|e| 
      plural = e.pluralize
      if plural != e && tags.index(plural)
        results << [e,plural]
      end
    }
    results
  end

  # @render_options :change_fields=>%w{word matches}, :filters=>{:default=>{'matches'=>:inspect}}
  # @options :distance=>3, :verbose=>:boolean, :length=>:numeric
  # Reports tags that are similar by a levenshtein distance.
  def find_similar_words(tags=nil, options={})
    tags ||= Tag.machine_tag_names
    tags = tags.select {|e| e.length >= options[:length] } if options[:length]
    require 'levenshtein'
    results = {}
    tags_by_letter = tags.inject({}) {|h,e| l = e[0,1]; h[l] ||= []; h[l] << e; h }
    tags_by_letter.each do |letter,words|
      if words.size > 1
        puts "Tags starting with '#{letter}'" if options[:verbose]
        words.each_with_index do |a,i|
          words[i+1, words.length-1].each_with_index do |b,j|
            puts "Checking #{a} with #{b}" if options[:verbose]
            distance = Levenshtein.distance(a, b)
            if (distance < options[:distance])
              puts "Found match: #{a}-#{b}: #{distance}" if options[:verbose]
              (results[a] ||= []) << b
            end
          end
        end
      else
        puts "Skipping tags starting with '#{letter}'" if options[:verbose]
      end
    end
    results
  end
end