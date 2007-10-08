class Identities < ActiveRecord::Base
	validates_presence_of :name, :description, :user_id
end
