require 'rubygems'
require 'activerecord'
require 'test/unit'
require 'context' #gem install jeremymcanally-context -s http://gems.github.com
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'has_machine_tags'

#Setup logger
require 'logger'
ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = Logger::WARN

#Setup db
ActiveRecord::Base.configurations = {'sqlite3' => {:adapter => 'sqlite3', :database => ':memory:'}}
ActiveRecord::Base.establish_connection('sqlite3')

require File.join(File.dirname(__FILE__), 'schema')


class TaggableModel < ActiveRecord::Base
end

class Test::Unit::TestCase
end
