
# Move the path to the location of the current file
Dir.chdir(File.dirname(File.expand_path(__FILE__)))

require '../../../IntuitiveFramework/IntuitiveFramework.rb'
require $IntuitiveFramework_Controllers
require $IntuitiveFramework_Servers
$ID_ENV = :development
ID::Config.load_config

# Create the servers
@communication_server = ID::Servers::CommunicationServer.new(:throw)
@project_server = ID::Servers::ProjectServer.new(:throw)
@project_server.clear_everything

# Add a user
public_key, private_key = ID::Models::EncryptionKey.make_public_and_private_keys
@user = ID::Models::User.new
@user.name = 'bobrick bobberton'
@user.public_universal_key = public_key.key.to_s
@user.private_key = private_key.key.to_s
@user.save!

# Create the project
@branch = ID::Models::Branch.new('Map Example Trunk', @user.public_universal_key)
@project = ID::Models::Project.new(@branch, 'Map Example')

document = ID::Models::Document.new(@project, 'Model')
document.data = File.new('models.xml').read
document.run_location = :client
document.document_type = :model

document = ID::Models::Document.new(@project, 'State')
document.data = File.new('state.xml').read
document.run_location = :client
document.document_type = :state

document = ID::Models::Document.new(@project, 'View')
document.data = File.new('view.xml').read
document.run_location = :client
document.document_type = :view

document = ID::Models::Document.new(@project, 'Controller')
document.data = File.new('controller.rb').read
document.run_location = :client
document.document_type = :controller

@project.main_controller_class_name = "MapController"
@project.main_view_name = "main_window"
ID::Controllers::DataController.save_revision(@branch)

# Advertise the project online
#@project_server.advertise_project_online(@project.name, @project.description, @project.parent_branch.user_id,
#                                         @project.parent_branch.head_revision_number, @project.project_number.to_s,
#                                         @project.parent_branch.branch_number.to_s)

# Look for the project online. Get its connection info from the web service.
# FIXME: for now we will just hard code the local connection, but it should
#         get the project server's socket and name from the 
#         search_for_projects_online function.
server_address = @project_server.net_address

# Load the program
program = ID::Program.new

ID::Servers::ProjectServer.run_project(server_address,
                                   @project.parent_branch.head_revision_number, 
                                   @project.project_number.to_s,
                                   @project.parent_branch.branch_number.to_s,
                                   program)

# Run the program
program.run
