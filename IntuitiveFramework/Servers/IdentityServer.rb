
# get the path of this file
path = File.dirname(File.expand_path(__FILE__))

require "#{path}/Namespace"

module Servers
	class IdentityServer
        attr_reader :identities, :local_connection
        
        def self.force_kill_other_instances
            return unless Controllers::SystemCommunicationController.is_name_used?("IdentityServer")
            
            unix_socket_file = Controllers::SystemCommunicationController.get_socket_file_name("IdentityServer")
            File.delete(unix_socket_file)
        end
        
        def initialize(logger_output)
            @communicator = Helpers::SystemProxy::get_proxy_to_object("CommunicationServer")
            
            # a hash to store known identities
            @identities = {}.extend(MonitorMixin)
            
            @local_connection = @communicator.create_net_connection
            
            @logger = Helpers::Logger.new(logger_output)
            
            # FIXME: To speed this up so it does not have to wait, move the guts of each 'when' to a function and do Thread.new { function_call }
            # Start a thread that responds to all requests
            @thread = Thread.new {
                loop do
                    while (mesage = @communicator.get_any_net_message(@local_connection)) == nil
                        sleep 0.1
                    end
                        case message[:command]
                            # The user wants to prove they are the owner of the identity
                            when :register_identity
                                begin
                                    # Get the identity information
                                    remote_connection = message[:source_connection]
                                    name = message[:name]
                                    public_key = message[:public_key]
            
                                    # Create another connection just for this conversation and tell the remote machine to use it
                                    temp_connection = @communicator.create_net_connection
                                    message = {:command => :ok_to_register_on_new_connection, :new_connection => temp_connection}
                                    @communicator.send_net_message(temp_connection, remote_connection, message)
            
                                    # Confirm that the remote machine got the connection
                                    while @communicator.get_net_message(temp_connection, :confirm_new_connection) == nil
                                        sleep 0.1
                                    end
            
                                    # Perform the standard identity ownership test
                                    Controllers::UserController.require_identity_ownership_test(
                                                                                        @communicator, 
                                                                                        temp_connection, 
                                                                                        remote_connection, 
                                                                                        name, 
                                                                                        public_key)
                                    # Remove the temporary connection     
                                    @communicator.destroy_net_connection(temp_connection)
                                                                                        
                                    # If get this far, save the identity
                                    @identities.synchronize {
                                        @identities[public_key] = {
                                            :name => name,
                                            :connection => remote_connection,
                                            :public_key => public_key }
                                    }
                                rescue
                                    @logger.log :info, "Threw durring register_identity: " + $!
                                end
                            
                            # User looksup an identity
                            when :find_virtual_identity
                                connection = message[:source_connection]
                                public_key = Models::EncryptionKey.new(message[:public_key], true)
                                
                                # Find a user that uses that public key
                                found_info = []
                                @identities.synchronize {
                                    if @identities.has_key?(public_key.key.to_s)
                                        found_info = @identities[public_key.key.to_s].dup
                                    else
                                        puts "Server: No identity registered '#{name}'"
                                    end
                                }
                                
                                # Send a message to the user to confirm that they are logged in
                                out_message = { :command => :found_virtual_identity,
                                            :name => found_info[:name],
                                            :connection => found_info[:connection],
                                            :public_key => found_info[:public_key] }
                                @communicator.send(@local_connection, connection, out_message)
                            else
                                @logger.log :info, "Identity server does not know the command '#{message[:command]}'."
                        end
                end
            }
            
            # Make the server available over the system communicator
            Helpers::SystemProxy.make_object_proxyable(self, "IdentityServer")
        end
        
        def is_open
            @communicator.is_open
        end
        
        def close
            @communicator.close if @communicator
            @thread.exit
            @logger.close
        end
        
        def has_identity?(public_key)
            @identities.has_key?(public_key)
        end
	end
end

