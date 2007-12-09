
require $IntuitiveFramework_Controllers
require $IntuitiveFramework_Servers

module ID; module Servers
	class TestIdentityServer < Test::Unit::TestCase
			def setup
			   # get sockets for the server, local machine and remote machine
			   @local_ip_address = '127.0.0.1'
			   @local_outgoing_port = 3000
			   @local_incoming_port = 3001
			   @server_ip_address = '127.0.0.1'
			   @server_incoming_port = 6000
			   @server_outgoing_port = 6001
			   
			   # Create a server and communication controller
               # Have the logger throw when it gets anything
               logger_exception = Proc.new { |status, message, exception| raise message }			   
			   @server = Servers::IdentityServer.new(logger_exception, @server_ip_address, @server_outgoing_port, @server_incoming_port)
			   @communicator = Controllers::CommunicationController.new(@local_ip_address,
			                                                       @local_incoming_port,
			                                                       @local_outgoing_port)
			                                                       
			   @local_connection = @communicator.create_connection                                                    
			                                                       
			   # create a test user
			   public_key, private_key = Models::EncryptionKey.make_public_and_private_keys
			   @user = Models::User.new
			   @user.name = 'bobrick'
			   @user.public_universal_key = public_key.key.to_s
			   @user.private_key = private_key.key.to_s
			   @user.save!
            end
            
            def teardown
                @server.close if @server
                @communicator.close if @communicator
                @user.destroy if @user
			end
			
			def test_log_works
			   warn "Make the log work instead of throwing."
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

