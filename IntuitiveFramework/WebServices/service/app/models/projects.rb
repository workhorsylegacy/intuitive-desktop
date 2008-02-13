class Projects < ActiveRecord::Base
	validates_presence_of :name, :description, :public_key, :revision, :project_number, :branch_number, :ip_address, :port, :connection_id
end
