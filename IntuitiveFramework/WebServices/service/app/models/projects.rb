class Projects < ActiveRecord::Base
	validates_presence_of :name, :description, :user_id, :revision, :project_number, :branch_number, :ip_address, :port, :connection_id
end
