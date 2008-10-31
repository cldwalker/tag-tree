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
  #change to your own editor
  def my_editor
    "vim -c 'setf vo_base'"
  end
  def edit_string(string)
    require 'tempfile'
    tempfile = Tempfile.new('edit')
    File.open(tempfile.path,'w') {|f| f.write(string) }
    system("#{my_editor} #{tempfile.path}")
    File.read(tempfile.path)
  end
  
end