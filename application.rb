ENV['RACK_ENV'] ||= 'development'
require 'rubygems' unless ENV['NO_RUBYGEMS']
APP_ROOT = File.dirname(__FILE__)
$: << "#{APP_ROOT}/lib"

require 'active_record'
require 'pg'
# hacks for has_machine_tags
require 'active_support/core_ext/class/attribute_accessors'
Rails = Module.new { def self.version() '3.0.0' end }
require 'has_machine_tags'

require 'console_update'
require 'boson'
Dir[APP_ROOT+'/models/*.rb'].each {|e| require e }

config = YAML.load_file('config/database.yml')[ENV['RACK_ENV']]
ActiveRecord::Base.establish_connection config
Boson.start
