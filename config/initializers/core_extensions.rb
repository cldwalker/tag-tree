class Array
  def count_hash
    count = {}
    each {|e|
      count[e] ||= 0
      count[e] += 1
    }
    count
  end
end