
require $IntuitiveFramework_Controllers
require $IntuitiveFramework_Servers

module ID; module Servers
	class TestIdentityServer < Test::Unit::TestCase
      def setup
          ID::TestHelper.cleanup()
          @communication_server = Servers::CommunicationServer.new("127.0.0.1", 5555, true, :throw)
          
          # Add 2 users
          @local_user = ID::Controllers::UserController::create_user('matt jones')
          @remote_user = ID::Controllers::UserController::create_user('bobrick')                
                
          # Have the logger throw when it gets anything
          @identity_server = Servers::IdentityServer.new(true, :throw)
      end
      
      def teardown
          @local_user.destroy if @local_user
          @remote_user.destroy if @remote_user
          
          @identity_server.close if @identity_server
          @communication_server.close if @communication_server
          
          ID::TestHelper.cleanup()      
      end
      
      def test_can_register_and_locate_user
         # Register the user
         passed =
         @identity_server.register_identity(@local_user.name,
                                           "The happy identity of your doom",
                                           @local_user.public_universal_key,
                                           @local_user.private_key)
         
         assert passed
         
         # Make sure we can find the identity
         identity_info = 
         @identity_server.find_identity(@local_user.public_universal_key)

         # Make sure the identity is the same
         assert_equal(@local_user.public_universal_key, identity_info[:public_key])
         assert_equal(@local_user.name, identity_info[:name])                            
      end
			
#			def test_cant_spoof_server
			   # Add a logger first, so the server can put errors in the log instead of throwing for the tests
			   # Try sending multiple register attempts in a DOS
			   # Try fake key and skipping to :challenge_virtual_identity
			   # Try faking key and skipping to :prove_virtual_identity
			   # Try sending many randomly named and keyed identities to overflow the server
			   # Try sending really small keys to break the server
			   # Try sending nil values to break the server
			   # Try sending blanks to break the server
#			   throw "Implement these tests!"
#			end
		end
end; end

