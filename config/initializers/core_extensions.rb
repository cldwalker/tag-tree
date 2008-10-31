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

class Object
  def edit_string(string)
    require 'tempfile'
    tempfile = Tempfile.new('edit')
    File.open(tempfile.path,'w') {|f| f.write(string) }
    system("#{ENV['editor'] || 'vim'} #{tempfile.path}")
    File.read(tempfile.path)
  end
  
end