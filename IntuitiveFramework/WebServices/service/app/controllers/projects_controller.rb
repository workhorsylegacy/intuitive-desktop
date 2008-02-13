
path = File.dirname(File.expand_path(__FILE__))
require "#{path}/../../../../IntuitiveFramework.rb"
require $IntuitiveFramework_Controllers
require $IntuitiveFramework_Models
require $IntuitiveFramework_Helpers
require $IntuitiveFramework_Views

# FIXME: Rename to IntuitiveController
class ProjectsController < ApplicationController
	wsdl_service_name 'Projects'
	web_service_api ProjectsApi
	web_service_scaffold :index

	def is_running
		true
	end

	def register_project(name, description, public_key, revision, project_number, branch_number, ip_address, port, connection_id)
		project = Projects.new
		project.name = name
		project.description = description
		project.public_key = public_key
		project.revision = revision
    project.project_number = project_number
    project.branch_number = branch_number
		project.ip_address = ip_address
    project.port = port
    project.connection_id = connection_id

		raise project.errors.collect { |e| "#{e.first}: #{e.last}" }.inspect unless project.save

		true
	end

	def search_projects(search)
		return unless search.strip.length > 0

		Projects.find(:all).collect do |p|
			[p.name, p.description, p.public_key, 
        p.revision, p.project_number, p.branch_number,
        p.ip_address, p.port, p.connection_id
      ] #if p.name.downcase.include? search.downcase # FIXME: A test. remove comment
		end.compact
	end

	def list_projects
		Projects.find(:all).collect do |p| 
      [p.name, p.description, p.public_key, 
        p.revision, p.project_number, p.branch_number,
        p.ip_address, p.port, p.connection_id]
    end
	end
  
  def list_identities
    Identities.find(:all).collect { |i| [i.name, i.public_key, i.description, i.ip_address, i.port, i.connection_id] }
  end
  
  def register_identity_start(name, public_key, description, ip_address, port, connection_id)
      encrypted_proof = ID::Controllers::UserController.create_ownership_test(public_key)
      
      encrypted_proof
  end
  
  def register_identity_end(name, public_key, description, ip_address, port, connection_id, decrypted_proof)
      passed = ID::Controllers::UserController.passed_ownership_test?(public_key, decrypted_proof)
            
    # Make sure the test passed
    raise "Failed to confirm identity for #{name}." unless passed
                            
    # If we got this far, save the identity
    identity = Identities.new
    identity.name = name
    identity.public_key = public_key
    identity.description = description
    identity.ip_address = ip_address
    identity.port = port
    identity.connection_id = connection_id

    raise identity.errors.collect { |e| "#{e.first}: #{e.last}" }.inspect unless identity.save
    
    ID::Controllers::UserController.clear_ownership_test(public_key)

    passed
  end

  def find_identity(public_key)
      identity = Identities.find(:first, :conditions => ["public_key = ?", public_key])

      return [] unless identity
      
      [identity.name, identity.public_key, identity.description,
      identity.ip_address, identity.port, identity.connection_id]
  end
  
  def empty_everything
    Projects.find(:all).each { |p| p.destroy }
    Identities.find(:all).each { |i| i.destroy }
    
    true
  end
end
