
require $IntuitiveFramework_Servers

module Servers
  class TestCommunicationServer < Test::Unit::TestCase
      # FIXME: We need to figure out how to stop and un-register a dbus service.
      # This is a hack to just turn it on and leave it on for all tests. This
      # is bad for unit testing. It should be restarted each time.
      @@communicator = nil
      @@user = nil
      
      def self.communicator
          if @@communicator == nil
               # Start the communication server
               Servers::CommunicationServer.start()
               @@communicator = Servers::CommunicationServer.get_communicator          
          end
          
          @@communicator
      end
      
      def self.user
          unless @@user
               # create a test user
               public_key, private_key = Models::EncryptionKey.make_public_and_private_keys
               @@user = Models::User.new
               @@user.name = 'bobrick'
               @@user.public_universal_key = public_key.key.to_s
               @@user.private_key = private_key.key.to_s
               @@user.save!         
          end
          
          @@user
      end
            
      def setup
          # FIXME: Because ruby dbus breaks when returning a large aas (array, array, string) 
          # Like in search_for_projects_online, we clear the database befor each test
          TestCommunicationServer.communicator.clear_everything
      end
            
      def teardown
          # FIXME: Because ruby dbus breaks when returning a large aas (array, array, string) 
          # Like in search_for_projects_online, we clear the database after each test
          TestCommunicationServer.communicator.clear_everything
      end
            
      def test_is_running
          assert(TestCommunicationServer.communicator.is_running)
      end
            
      def test_advertise_project_online
          # Create the project in a local repository
          branch = Models::Branch.new('Map Example Trunk', TestCommunicationServer.user.public_universal_key)
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
          assert(TestCommunicationServer.communicator.advertise_project_online(project))
          
          # Look up the project online and make sure it is the same
          begin
              details = TestCommunicationServer.communicator.search_for_projects_online("Map Example")
          rescue Exception
              raise "This will explode because there seems to be a limit to the size of a dbus message."
          end
          assert_equal(project.name, details.first[:name])
          assert_equal(project.description, details.first[:description])
          assert_equal(project.parent_branch.user_id, details.first[:user_id])
          assert_equal(project.parent_branch.head_revision_number, details.first[:revision])
          assert_equal(project.project_number.to_s, details.first[:project_number])
      end
      
      def test_run_project_online
          # Create the project in a local repository
          branch = Models::Branch.new('Map Example Trunk', TestCommunicationServer.user.public_universal_key)
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
          assert(TestCommunicationServer.communicator.advertise_project_online(project))
          
          TestCommunicationServer.communicator
      end
    end
end

