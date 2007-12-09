
require $IntuitiveFramework_Controllers
require $IntuitiveFramework_Servers

module ID; module Controllers
  #FIXME: Rename to TestIdentityController
	class TestUserController < Test::Unit::TestCase
			def setup
          Servers::CommunicationServer.force_kill_other_instances()
          Servers::IdentityServer.force_kill_other_instances()
          
          @communication_server = Servers::CommunicationServer.new("127.0.0.1", 5555, true, :throw)
          
                # Add 2 users
                @local_user = UserController::create_user('matt jones')
                @local_connection = @communication_server.create_net_connection
                
                @remote_user = UserController::create_user('bobrick')
                @remote_connection = @communication_server.create_net_connection                
                
                # Have the logger throw when it gets anything
                @identity_server = Servers::IdentityServer.new(true, :throw)
      end
            
            def teardown
                @local_user.destroy if @local_user
                @remote_user.destroy if @remote_user
                
                @identity_server.close if @identity_server
                @communication_server.close if @communication_server
			end
			
			def test_can_prove_identity
          encrypted_proof = Controllers::UserController.create_ownership_test(@local_user.public_universal_key)
          
          decrypted_proof = Controllers::UserController.answer_ownership_test(@local_user.private_key, encrypted_proof)
          
          passed = Controllers::UserController.passed_ownership_test?(@local_user.public_universal_key, decrypted_proof)
          
          assert passed
			end
			
			def test_can_register_and_locate_user
			   # Register the user
         passed =
			   @identity_server.register_identity(@local_connection, 
                                           @local_user.name,
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
		end
end; end

