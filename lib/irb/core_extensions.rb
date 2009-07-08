module MyArray
  def amap(*fields)
    map {|e| fields.map {|field| e.send(field) }}
  end

  def method_missing(method,*args,&block)
    shortcut_klasses = [ActiveRecord::Base]
    #if all have one of shortcut klasses as an ancestor
    if !self.empty? && self.all? {|e| shortcut_klasses.any? {|k| e.is_a?(k)} }
      self.map {|e| e.send(method,*args,&block) }
    else
      super
    end
  end
end

Array.send :include, MyArray
