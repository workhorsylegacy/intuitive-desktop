
class ProjectsController < ApplicationController
	wsdl_service_name 'Projects'
	web_service_api ProjectsApi
	web_service_scaffold :index

	def is_running
		true
	end

	def register_project(name, description, user_id, revision, project_number)
		project = Projects.new
		project.name = name
		project.description = description
		project.user_id = user_id
		project.revision = revision
    project.project_number = project_number
		project.location = self.request.env["REMOTE_ADDR"]

		raise project.errors.collect { |e| "#{e.first}: #{e.last}" }.inspect unless project.save

		true
	end

	def register_identity(name, user_id, description)
		identity = Identities.new
		identity.name = name
		identity.description = description
		identity.user_id = user_id

		raise identity.errors.collect { |e| "#{e.first}: e.last" }.inspect unless identity.save

		true
	end

	def search_identities(search)
		[]
	end

	def search_projects(search)
		return unless search.strip.length > 0

		Projects.find(:all).collect do |p|
			[
        p.name, 
        p.description, 
        p.user_id, 
        p.revision, 
        p.project_number, 
        p.location
      ] if p.name.downcase.include? search.downcase
		end.compact
	end

	def list_identities
		Identities.find(:all).collect { |i| [i.name, i.user_id, i.description] }
	end

	def list_projects
		Projects.find(:all).collect do |p| 
      [p.name, p.description, p.user_id, p.revision, p.project_number, p.location]
    end
	end
  
  def empty_everything
    Projects.find(:all).each { |p| p.destroy }
    Identities.find(:all).each { |i| i.destroy }
    
    true
  end
end
