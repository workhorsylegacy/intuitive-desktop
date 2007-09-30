
# Move the path to the location of the current file
Dir.chdir(File.dirname(File.expand_path(__FILE__)))

require '../../../IntuitiveFramework/IntuitiveFramework.rb'
require $IntuitiveFramework_Controllers
require $IntuitiveFramework_Servers

# Create a document server
proc = Proc.new { |status, message, exception| 
    raise exception if exception
    raise message
}
@document_server = Servers::DocumentServer.new('127.0.0.1', 5000, 5001, proc)

# Create a communication controller to talk to the server
@communicator = Controllers::CommunicationController.new('127.0.0.1', 6000, 6001)
@connection = @communicator.create_connection

# Add a user
public_key, private_key = Models::EncryptionKey.make_public_and_private_keys
@user = Models::User.new
@user.name = 'bobrick bobberton'
@user.public_universal_key = public_key.key.to_s
@user.private_key = private_key.key.to_s
@user.save!

# Create the project
@branch = Models::Branch.new('Map Example Trunk', @user.public_universal_key)
@project = Models::Project.new(@branch, 'Map Example')

document = Models::Document.new(@project, 'Model')
document.data = File.new('models.xml').read
document.run_location = :client
document.document_type = :model

document = Models::Document.new(@project, 'State')
document.data = File.new('state.xml').read
document.run_location = :client
document.document_type = :state

document = Models::Document.new(@project, 'View')
document.data = File.new('view.xml').read
document.run_location = :client
document.document_type = :view

document = Models::Document.new(@project, 'Controller')
document.data = File.new('controller.rb').read
document.run_location = :client
document.document_type = :controller

@project.main_controller_class_name = "MapController"
@project.main_view_name = "main_window"
Controllers::DataController.save_revision(@branch)

# Create a window to run all the examples in
desktop = Window.new

# Load the example program into a tab
program = Program.new(window)

# Have the Client ask the Server to run the Document
Controllers::DataController.run_project_over_network(@communicator,
                                                      @connection,
                                                      @document_server.local_connection,
                                                      window,
                                                      program,
                                                      @project,
                                                      @branch)

## FIXME: For now run the document locally so we won't have to deal with Proxy issues.
#Controllers::DataController.run_project_locally(window, program, @project)

# Have the window run all the programs
window.run
