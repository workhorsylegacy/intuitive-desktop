
require $IntuitiveFramework_Servers

module ID; module Servers
  class TestProjectServer < Test::Unit::TestCase
      def setup
          # Start the communication server
          ID::TestHelper.cleanup()
          @communication_server = Servers::CommunicationServer.new(:throw)
          
          # create a test user
          public_key, private_key = Models::EncryptionKey.make_public_and_private_keys
          @user = Models::User.new
          @user.name = 'bobrick'
          @user.public_universal_key = public_key.key.to_s
          @user.private_key = private_key.key.to_s
          @user.save! 
          
          @project_server = Servers::ProjectServer.new(:throw)
          @project_server.clear_everything
      end
            
      def teardown
          @project_server.clear_everything if @project_server

          @project_server.close if @project_server
          @communication_server.close if @communication_server
          
          @user.destroy if @user
          
          ID::TestHelper.cleanup()
      end
            
      def test_is_running
          assert(@project_server.is_running)
      end

      def test_advertise_project_online
          # Create the project in a local repository
          branch = Models::Branch.new('Map Example Trunk', @user.public_universal_key)
          project = Models::Project.new(branch, 'Map Example')
          project.description = "A simple map program. Allows you to search for locations by name, and see them on the map."
          
          document = Models::Document.new(project, 'Model')
          document.data = File.new('../examples/large_examples/maps/models.xml').read
          document.run_location = :client
          document.document_type = :model
          
          document = Models::Document.new(project, 'State')
          document.data = File.new('../examples/large_examples/maps/state.xml').read
          document.run_location = :client
          document.document_type = :state
          
          document = Models::Document.new(project, 'View')
          document.data = File.new('../examples/large_examples/maps/view.xml').read
          document.run_location = :client
          document.document_type = :view
          
          document = Models::Document.new(project, 'Controller')
          document.data = File.new('../examples/large_examples/maps/controller.rb').read
          document.run_location = :client
          document.document_type = :controller
          
          project.main_controller_class_name = "MapController"
          project.main_view_name = "main_window"
          Controllers::DataController.save_revision(branch)     
          
          # Advertise the project online
          @project_server.advertise_project_online(project.name, project.description, project.parent_branch.user_id,
                                                   project.parent_branch.head_revision_number, project.project_number.to_s,
                                                   project.parent_branch.branch_number.to_s)
          
          # Look up the project online and make sure it is the same
          details = @project_server.search_for_projects_online("Map Example")
          
          assert_equal(project.name, details.first[:name])
          assert_equal(project.description, details.first[:description])
          assert_equal(project.parent_branch.user_id, details.first[:user_id])
          assert_equal(project.parent_branch.head_revision_number, details.first[:revision])
          assert_equal(project.project_number.to_s, details.first[:project_number])
      end
   
      def test_search_projects
          raise "Implement me!"
      end
   
      def test_run_project_online
          # Create the project in a local repository
          branch = Models::Branch.new('Map Example Trunk', @user.public_universal_key)
          project = Models::Project.new(branch, 'Map Example')
          project.description = "A simple map program. Allows you to search for locations by name, and see them on the map."
          
          document = Models::Document.new(project, 'Model')
          document.data = File.new('../examples/large_examples/maps/models.xml').read
          document.run_location = :client
          document.document_type = :model
          
          document = Models::Document.new(project, 'State')
          document.data = File.new('../examples/large_examples/maps/state.xml').read
          document.run_location = :client
          document.document_type = :state
          
          document = Models::Document.new(project, 'View')
          document.data = File.new('../examples/large_examples/maps/view.xml').read
          document.run_location = :client
          document.document_type = :view
          
          document = Models::Document.new(project, 'Controller')
          document.data = File.new('../examples/large_examples/maps/controller.rb').read
          document.run_location = :client
          document.document_type = :controller
          
          project.main_controller_class_name = "MapController"
          project.main_view_name = "main_window"
          Controllers::DataController.save_revision(branch)     
          
          # Advertise the project online
          @project_server.advertise_project_online(project.name, project.description, project.parent_branch.user_id,
                                                   project.parent_branch.head_revision_number, project.project_number.to_s,
                                                   project.parent_branch.branch_number.to_s)
          
          # Look for the project online. Get its connection info from the web service.
          # FIXME: for now we will just hard code the local connection, but it should
          #         get the project server's socket and name from the 
          #         search_for_projects_online function.
          server_address = @project_server.net_address
          
          # Create a local program that is running off the document server
          program = Program.new
          Servers::ProjectServer.run_project(server_address,
                                             project.parent_branch.head_revision_number, 
                                             project.project_number.to_s,
                                             project.parent_branch.branch_number.to_s,
                                             program)
                                             
      end
    end
end; end

