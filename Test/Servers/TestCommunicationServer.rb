
require $IntuitiveFramework_Servers

module Servers
  class TestCommunicationServer < Test::Unit::TestCase
      @communication_server = nil
      @user = nil
            
      def setup
          Servers::CommunicationServer.force_kill_other_instances()
          
          # Start the communication server
          @real_communication_server = Servers::CommunicationServer.new("127.0.0.1", 5555, 6666, true, :throw)
          @server_communicator = Controllers::SystemCommunicationController.new()
          @communication_server = Helpers::SystemProxy.get_proxy_to_object("CommunicationServer", @server_communicator)
          
          # create a test user
          public_key, private_key = Models::EncryptionKey.make_public_and_private_keys
          @user = Models::User.new
          @user.name = 'bobrick'
          @user.public_universal_key = public_key.key.to_s
          @user.private_key = private_key.key.to_s
          @user.save! 
          
          @communication_server.clear_everything
          
          # Create the document server
          proc = Proc.new do |status, message, exception| 
              raise exception if exception
              raise message
          end
          
          @real_document_server = Servers::DocumentServer.new("127.0.0.1", 5000, 6000, proc)
          @document_communicator = Controllers::SystemCommunicationController.new()
          @document_server = Helpers::SystemProxy.get_proxy_to_object("DocumentServer", @document_communicator)
      end
            
      def teardown
          @communication_server.clear_everything if @communication_server
          
          @server_communicator.close if @server_communicator
          @document_communicator.close if @document_communicator
          
          @real_communication_server.close if @real_communication_server
          @real_document_server.close if @real_document_server
          
          @user.destroy if @user
      end
            
      def test_is_running
          assert(@communication_server.is_running)
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
          assert(@communication_server.advertise_project_online(project))
          
          # Look up the project online and make sure it is the same
          details = @communication_server.search_for_projects_online("Map Example")
          
          assert_equal(project.name, details.first[:name])
          assert_equal(project.description, details.first[:description])
          assert_equal(project.parent_branch.user_id, details.first[:user_id])
          assert_equal(project.parent_branch.head_revision_number, details.first[:revision])
          assert_equal(project.project_number.to_s, details.first[:project_number])
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
          connection = @communication_server.advertise_project_online(project)
          assert_not_nil(connection)
          
          # Create a local program that is running off the document server
          program = Program.new
          @communication_server.run_project(project.parent_branch.head_revision_number, 
                                                            project.project_number.to_s,
                                                            project.parent_branch.branch_number.to_s,
                                                            @document_server.generic_net_connection,
                                                            program)
      end
    end
end

