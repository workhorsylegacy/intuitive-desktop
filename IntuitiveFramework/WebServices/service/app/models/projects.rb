class Projects < ActiveRecord::Base
	validates_presence_of :name, :description, :user_id, :revision, :location
end
