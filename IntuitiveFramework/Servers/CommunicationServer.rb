

module Servers
    # FIXME: Have this replace the DataController. Trash the old one.
    class CommunicationServer
        def self.force_kill_other_instances
            return unless Controllers::SystemCommunicationController.is_name_used?("CommunicationServer")
            
            unix_socket_file = Controllers::SystemCommunicationController.get_socket_file_name("CommunicationServer")
            File.delete(unix_socket_file)
        end
        
        def initialize(ip_address, in_port, out_port, use_local_web_service, on_error)
            # Make sure the on_error is valid
            on_error_options = [:log_to_file, :log_to_std_error, :throw]
            message = "The Communication Server can only use #{on_error_options.join(', ')} for on_error."
            raise message unless on_error_options.include? on_error.to_sym
            @on_error = on_error

            # Create the net communicator
            @net_communicator = Controllers::CommunicationController.new(ip_address, in_port, out_port)

            # Make the server available over the system communicator
            Helpers::SystemProxy.make_object_proxyable(self, "CommunicationServer")
        end
        
        def is_running?
            true
        end
        
        def close
            @net_communicator.close if @net_communicator
        end
            
        def ip_address
            @net_communicator.ip_address
        end
            
        def in_port
            @net_communicator.in_port
        end
            
        def out_port
            @net_communicator.out_port
        end
            
        def on_error
            @on_error.to_s
        end
            
        def create_net_connection
            @net_communicator.create_connection
        end
            
        def destroy_net_connection(connection)
            @net_communicator.destroy_connection(connection)
        end
            
        def send_net_message(source_connection, dest_connection, message)
            @net_communicator.send(source_connection, dest_connection, message)
        end            
            
        def wait_for_net_message(connection, message)
            @net_communicator.wait_for_command(connection, message)
        end
            
        def wait_for_any_net_message(connection)
            raise "This method does not except a code block." if block_given?
            @net_communicator.wait_for_any_command(connection) {}
        end
    end
end

