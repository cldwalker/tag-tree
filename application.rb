ENV['RACK_ENV'] ||= 'development'
require 'rubygems' unless ENV['NO_RUBYGEMS']
APP_ROOT = File.dirname(__FILE__)
$: << "#{APP_ROOT}/lib"

require 'active_record'
require 'rails'
require 'pg'
require 'has_machine_tags'
require 'console_update'
Dir[APP_ROOT+'/models/*.rb'].each {|e| require e }

config = YAML.load_file('config/database.yml')[ENV['RACK_ENV']]
ActiveRecord::Base.establish_connection config
