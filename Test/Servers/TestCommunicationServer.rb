
require $IntuitiveFramework_Servers

module Servers
  class TestCommunicationServer < Test::Unit::TestCase
      # FIXME: We need to figure out how to stop and un-register a dbus service.
      # This is a hack to just turn it on and leave it on for all tests. This
      # is bad for unit testing. It should be restarted each time.
      @@did_setup = false
      
      def setup
         return if @@did_setup
         @@did_setup = true
         
         # Start the communication server
         Servers::CommunicationServer.start()
         @@communicator = Servers::CommunicationServer.get_communicator
                                                             
         # create a test user
         public_key, private_key = Models::EncryptionKey.make_public_and_private_keys
         @@user = Models::User.new
         @@user.name = 'bobrick'
         @@user.public_universal_key = public_key.key.to_s
         @@user.private_key = private_key.key.to_s
         @@user.save!
      end
            
      def test_is_running
          assert(@@communicator.is_running)
      end
            
      def test_advertise_project_online
          # Create the project
          branch = Models::Branch.new('Map Example Trunk', @@user.public_universal_key)
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
          assert(@@communicator.advertise_project_online(project))
          
          # Look up the project online and make sure it is the same
          details = @@communicator.search_for_projects_online("Map Example")
          assert_equal(project.name, details[:name])
          assert_equal(project.description, details[:description])
          assert_equal(project.parent_branch.user_id, details[:user_id])
          assert_equal(project.parent_branch.revision_number, details[:revision_number])
      end
            
#      def teardown
#          Servers::CommunicationServer.stop()
#          @user.destroy if @user
#      end
    end
end

