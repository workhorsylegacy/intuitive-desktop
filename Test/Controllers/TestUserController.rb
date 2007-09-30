
require $IntuitiveFramework_Controllers
require $IntuitiveFramework_Servers

module Controllers
	class TestUserController < Test::Unit::TestCase
			def setup
                # Add 2 users
                @local_user = UserController::create_user('matt jones')
                @local_communicator = CommunicationController.new('127.0.0.1', 5000, 5001)
                @local_connection = @local_communicator.create_connection
                
                @remote_user = UserController::create_user('bobrick')
                @remote_communicator = CommunicationController.new('127.0.0.1', 3000, 3001)
                @remote_connection = @remote_communicator.create_connection                
                
                # Have the logger throw when it gets anything
                logger_exception = Proc.new { |status, message, exception| raise message }
                @server = Servers::IdentityServer.new(logger_exception, '127.0.0.1', 6000, 6001)
            end
            
            def teardown
                @local_user.destroy if @local_user
                @remote_user.destroy if @remote_user
                
                @local_communicator.close
                @remote_communicator.close
                
                @server.close if @server
			end
			
			def test_can_prove_identity
                require_thread = Thread.new {
                    UserController::require_identity_ownership_test(
                                                        @local_communicator, 
                                                        @local_connection, 
                                                        @remote_connection, 
                                                        @remote_user.name, 
                                                        @remote_user.public_universal_key)
                }
			
                satisfy_thread = Thread.new {
                    UserController::satisfy_identity_ownership_test(
                                                        @remote_communicator, 
                                                        @remote_connection, 
                                                        @local_connection, 
                                                        @remote_user)
                }
                
                require_thread.join
                satisfy_thread.join
			end
			
			def test_can_register_and_locate_user
			   # Register the 2 users
			   UserController::register_identity(@local_communicator, 
			                                 @local_connection, 
			                                 @server.local_connection, 
			                                 @local_user)
			   
			   # Make sure we can find the 2 users
			   copy_local_user = UserController::find_user(@local_communicator,
			                             @local_connection,
			                             @server.local_connection,
			                             @local_user.public_universal_key)

                # Make sure the found Identities are correct
                assert_equal(@local_user.public_universal_key, copy_local_user.public_universal_key)
                assert_equal(@local_user.name, copy_local_user.name)                            
			end
		end
end

