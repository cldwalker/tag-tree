require 'yaml'
module Iam
  class <<self
    def config(reload=false)
      @config = YAML::load_file('config/iam.yml') if reload || @config.nil?
      @config
    end

    def commands
      (@commands ||= []) + create_class_commands(Iam)
    end
    
    def commands_with_description
      @description_commands ||= commands.select {|e| e[:description] }
    end

    def register(*args)
      @commands = []
      args.each {|e| @commands += create_class_commands(e)}
    end
    
    def create_class_commands(klass)
      klass.instance_methods.map {|e|
        {:name=>e, :description=>(config['commands'][e]['description'] rescue nil)}
      }
    end
  end
  
  def list
    print_commands Iam.commands_with_description
  end
  
  def search(query='')
    print_commands Iam.commands_with_description.select {|e| e[:name] =~ /#{query}/}
  end

  private
  def print_commands(commands)
    puts Hirb::Helpers::Table.render(commands, :fields=>[:name, :description])
  end
end