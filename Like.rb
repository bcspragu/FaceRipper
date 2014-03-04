require 'rubygems'
require 'active_record'
require 'yaml'
 
dbconfig = YAML::load(File.open('config/database.yml'))
ActiveRecord::Base.establish_connection(dbconfig)
 
class Like < ActiveRecord::Base
  belongs_to :user
  belongs_to :status
end
