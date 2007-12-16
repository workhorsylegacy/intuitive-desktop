
require 'monitor'
require 'socket'

# FIXME: Rename to NetCommunicationController
# TODO: Intead of using YAML to convert the messages to strings, use binary
# TODO: Figure out how to make the wait_for methods not need to use fast sleep counts to be responsive
module ID; module Controllers
    class CommunicationController
	    attr_reader :ip_address, :in_port, :is_open, :is_incoming_open
	    
	    def initialize(ip_address, in_port)
	        # Validate arguments
	        # FIXME: Add validation for ports and ip address format
	        raise "IP address was nil." unless ip_address
	        raise "Incoming port number was nil." unless in_port
	        
	        # Save network info
	        @ip_address = ip_address
	        @in_port = in_port
	        
	        # Get variables to store message and id info
	        @connections = {}.extend(MonitorMixin)
	        @in_commands = {}.extend(MonitorMixin)
	        
	        self.open
	    end
	    
	    # Connections hold ip_address, port, and connection_id
	    def create_connection
	        @connections.synchronize {
	            # Find a connection id that has not been used yet
	            new_id = nil
	            loop do
	                new_id = rand(2**16)
	                break unless @connections.has_key?(new_id)
	                sleep(0.01)
	            end
	            
	            # Save the new id
	            @connections[new_id] = { :ip_address => @ip_address, :port => @in_port, :id => new_id }
	            @in_commands[new_id] = [].extend(MonitorMixin)
	            
	            @connections[new_id]
	        }
	    end
	    
	    def destroy_connection(connection)
	        @connections.synchronize {
                id = connection[:id]
	            @connections.delete(id)
	            @in_commands.delete(id)
	        }
	    end
	    
	    # Will block until the next command is received, then return it
	    def wait_for_any_command(connection)
            # Make sure the connection is valid
            validate_connection(connection)
            id = connection[:id]
            
	        loop do
	           message = nil
	           @in_commands.synchronize do
    	           if @in_commands[id].length > 0
    	               message = @in_commands[id].shift
    	           end
	           end
	           
	           if message != nil
	               yield(message) if block_given?
	               return message
	           else
	               sleep(0.1)
	           end
	        end
	    end            
	    
	    # Will wait for a command up to a certain amount of time before throwing
	    def wait_for_command(connection, command, max_seconds_to_wait=10)
            # Make sure the connection is valid
            validate_connection(connection)
	        
	        start_time = Time.now
	        user_commands = @in_commands[connection[:id]]
	        retval = nil
	        loop do
	            #user_commands.synchronize {
	                user_commands.each { |user_command|
	                    if user_command[:command] == command
	                        retval = user_commands.delete(user_command)
	                        break
	                    end
	                }
	            #}
	            break if retval
	            raise "Timed out while waiting for the command '#{command}'" if (Time.now - start_time).to_i > max_seconds_to_wait
	            sleep(0.1)
	        end
	        
	        return retval
	    end            
	    
        def send_command(source_connection, dest_connection, message)
            # Make sure the socket is open
            raise "The outgoing channel is closed" unless @is_open
                    
            # Make sure the arguments are valid
            raise "The message to send was nil" unless message
            raise "The destination connection info is nil" unless dest_connection
            raise "The source connection info is nil" unless source_connection
            
            # Make sure the local connection is valid
            raise "The source connection does not belong to this Communication Controller." unless @connections.has_key?(source_connection[:id])
            
            # Get the complete connection info
            complete_message = message.merge({:source_connection => source_connection, 
                                              :dest_connection => dest_connection})
            
            # Get the message in YAML format
            message_yaml = YAML.dump(complete_message)
            
            # FIXME:  Make this only re-connect if the connection is different
            out_socket = nil
            begin
                out_socket = TCPSocket.open(dest_connection[:ip_address], dest_connection[:port])
                out_socket.send(message_yaml, 0)
            ensure
                out_socket.close if out_socket
            end
        end
	    
	    def open
	        #just return if already open
	        return if @is_open

	        start_incoming_thread
	        
	        @is_open = true
	    end
	        
	    def close
	        #just return if already closed
	        return unless @is_open
	        
	        stop_incoming_thread
	        
	        @is_open = false
	    end
	    
	    private
	    
	    def start_incoming_thread
            begin
                @in_socket = TCPServer.open(@ip_address, @in_port)
	        rescue Errno::EADDRINUSE
	           raise "Communication controller could not bind to address: #{@ip_address}:#{@in_port} because it is already in use."
	        end
	            
	        @in_thread = Thread.new {
	            @is_incoming_open = true
	            while @is_incoming_open
                  begin
                      sock = @in_socket.accept_nonblock
	                    result = YAML.load(sock.read)
                      sock.close
                  rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
                      IO.select([@in_socket])
                      retry
                  end

	                raise "Incoming message not a Hash." unless result.class == Hash
	                raise "Incoming message missing source_connection." unless result.has_key?(:source_connection)
	                raise "Incoming message missing dest_connection." unless result.has_key?(:dest_connection)
	                id = result[:dest_connection][:id]
	                
#	                # FIXME: Dump the message here if it was sent to the wrong controller
#	                raise "Wrong connection " + result.inspect unless @connections.has_key?(id)
	                
	                # Make sure we know of this connection
	                raise "There is no destination connection on this controller that matches that id." unless @connections.has_key?(id)
	                
	                @in_commands.synchronize { @in_commands[id] << result }
	            end
	        }
	    end
	    
	    def stop_incoming_thread
	        @is_incoming_open = false
	        # FIXME: We need a way to cancel the socket's recvfrom call and wait for the thread
	        # to finish. Then we can kill it if it takes more then 5 seconds to exit. Also flush
	        # its message que on kill?
	        @in_thread.exit
	        @in_socket.close
	    end
	    
	    def validate_connection(connection)
            if connection[:ip_address] != @ip_address || connection[:port] != @in_port
                raise "The connection does not belong to this Communication Controller"
            end
        end
    end
end; end

