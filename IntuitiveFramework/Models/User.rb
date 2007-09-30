
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Group"

module Models
	 class User < ActiveRecord::Base
            establish_connection(Models::USER_DATABASE_CONNECTION)
  
		has_many :documents
		has_many :deltas
		has_and_belongs_to_many :groups
		validates_presence_of :name
		validates_presence_of :public_universal_key
		validates_uniqueness_of :public_universal_key
		validates_presence_of :private_key
	end
end
