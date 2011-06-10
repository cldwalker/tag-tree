ENV['RACK_ENV'] ||= 'development'
require 'rubygems' unless ENV['NO_RUBYGEMS']
APP_ROOT = File.dirname(__FILE__)
$: << "#{APP_ROOT}/lib"

require 'active_record'
require 'pg'
require 'has_machine_tags'
require 'console_update'
require 'boson'
require 'erb'
Dir[APP_ROOT+'/models/*.rb'].each {|e| require e }
Dir[APP_ROOT+'/lib/*.rb'].each {|e| require e }

config = YAML.load(
  ERB.new(File.read('config/database.yml')).result
)[ENV['RACK_ENV']]
ActiveRecord::Base.establish_connection config
Alias.create
Boson.start
