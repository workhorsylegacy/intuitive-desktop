
require 'monitor'
require 'socket'
require 'fileutils'

module Controllers
    class SystemCommunicationController
      attr_reader :name, :is_open, :is_incoming_open, :is_outgoing_open
      
      # FIXME: Move this into the project folder for now
      @@file_path = "/home/matt/Desktop/poop/"
      
      def initialize(name)
          # Validate arguments
          raise "Name cannot be nil." unless name
          raise "The name '#{name}' is already used by a service." if is_name_used? name
          
          # Save network info
          @name = name
          @full_name = @@file_name + name
          
          # Get variables to store message and id info
          @connections = {}.extend(MonitorMixin)
          @in_commands = {}.extend(MonitorMixin)
          
          self.open
      end
      
      def self.is_name_used?(name)
          full_name = @@file_path + name
          
          # If the file exist, and we can connect to it, it is used
          if File.exist?(full_name)
              s = nil
              begin
                  s = UNIXSocket.new(full_name)
                  return true
              rescue
              ensure
                  s.close if s
              end
          end
          
          return false
      end
      
      # Returns a connection, which is a name and connection id
      def self.create_connection(name)
          @connections.synchronize do
              # Find a connection id that has not been used yet
              new_id = nil
              loop do
                  new_id = rand(2**16)
                  break unless @connections.has_key?(new_id)
                  sleep(0.01)
              end
              
              # Save the new id
              @connections[new_id] = { :name => @name, :id => new_id }
              @in_commands[new_id] = [].extend(MonitorMixin)
              
              @connections[new_id]
          end
      end
      
      def self.destroy_connection(name, connection)
          @connections.synchronize do
                id = connection[:id]
              @connections.delete(id)
              @in_commands.delete(id)
          end
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
                 yield(message)
                 return message
             else
                 sleep(0.01)
             end
          end
      end            
      
      # Will wait for a command up to a certain amount of time before throwing
      def wait_for_command(connection, command, max_seconds_to_wait=5)
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
              sleep(0.01)
          end
          
          return retval
      end            
      
        def send(source_connection, dest_connection, message)
            # Make sure the socket is open
            raise "The outgoing channel is closed" unless @is_open
                    
            # Make sure the arguments are valid
            raise "The message to send was nil" unless message
            raise "The destination connection info is nil" unless dest_connection
            
            # Make sure the local connection is valid
            raise "The source connection does not belong to this Communication Controller." unless @connections.has_key?(source_connection[:id])
            
            # Get the complete connection info
            complete_message = message.merge({:source_connection => source_connection, 
                                              :dest_connection => dest_connection})
            
            # Get the message in YAML format and make sure it is not too big for the socket
            message_yaml = YAML.dump(complete_message)
            raise "Can't send message because it is bigger than #{MESSAGE_SIZE}!" if message_yaml.length > MESSAGE_SIZE
            
            # FIXME:  Make this only re-connects if the connection is different
            @out_socket.connect(dest_connection[:ip_address], dest_connection[:port])
            @out_socket.send(message_yaml, 0)
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
              @in_socket = UNIXServer.new(@full_name)
          rescue
             raise "System Communication Controller could not bind to name #{@name} because it is already in use."
          end
              
          @in_thread = Thread.new do
              @is_incoming_open = true
              while @is_incoming_open
                  result = nil
                  begin
                      sock = server.accept_nonblock
                      result = YAML.load(sock.read)
                  rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
                      IO.select([@in_socket])
                      retry
                  end

                  raise "Incoming message not a Hash." unless result.class == Hash
                  raise "Incoming message missing source_connection." unless result.has_key?(:source_connection)
                  raise "Incoming message missing dest_connection." unless result.has_key?(:dest_connection)
                  id = result[:dest_connection][:id]
                  
                  # FIXME: Dump the message here if it was sent to the wrong controller
                  raise @connections.inspect unless @connections.has_key?(id)
                  
                  # Make sure we know of this connection
                  raise "There is no destination connection on this controller that matches that id." unless @connections.has_key?(id)
                  
                  @in_commands.synchronize { @in_commands[id] << result }
              end
          end
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
            if connection[:name] != @name
                raise "The connection does not belong to this Communication Controller"
            end
        end
    end
end

