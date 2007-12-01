
require $IntuitiveFramework_Controllers
require $IntuitiveFramework_Servers

module Controllers
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
                logger_exception = Proc.new { |status, message, exception| raise message }
                @identity_server = Servers::IdentityServer.new(logger_exception)
      end
            
            def teardown
                @local_user.destroy if @local_user
                @remote_user.destroy if @remote_user
                
                @identity_server.close if @identity_server
                @communication_server.close if @communication_server
			end
			
#			def test_can_prove_identity
#                require_thread = Thread.new {
#                    UserController::require_identity_ownership_test(
#                                                        @communication_server, 
#                                                        @local_connection, 
#                                                        @remote_connection, 
#                                                        @remote_user.name, 
#                                                        @remote_user.public_universal_key)
#                }
#			
#                satisfy_thread = Thread.new {
#                    UserController::satisfy_identity_ownership_test(
#                                                        @communication_server, 
#                                                        @remote_connection, 
#                                                        @local_connection, 
#                                                        @remote_user)
#                }
#                
#                require_thread.join
#                satisfy_thread.join
#			end
			
			def test_can_register_and_locate_user
			   # Register the 2 users
			   UserController::register_identity(@communication_server, 
			                                 @local_connection, 
			                                 @identity_server.local_connection, 
			                                 @local_user)
			   
         raise "done"
			   # Make sure we can find the 2 users
			   copy_local_user = UserController::find_user(@communication_server,
			                             @local_connection,
			                             @identity_server.local_connection,
			                             @local_user.public_universal_key)

                # Make sure the found Identities are correct
                assert_equal(@local_user.public_universal_key, copy_local_user.public_universal_key)
                assert_equal(@local_user.name, copy_local_user.name)                            
			end
		end
end

