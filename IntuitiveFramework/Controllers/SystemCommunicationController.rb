
require 'monitor'
require 'socket'
require 'fileutils'

module Controllers
    class SystemCommunicationController
      attr_reader :name, :is_open, :is_incoming_open, :is_outgoing_open
      
      def initialize(name = :random)
          # Make sure the temp directory exist
          FileUtils.mkdir(self.class.file_path) unless File.directory?(self.class.file_path)
          
          # Validate arguments
          raise "The name cannot be nil" unless name
          raise "The name '#{name}' is already used by a service." if name != :random && self.class.is_name_used?(name)
          
          # Generate a random name if it was nil
          if name == :random
              new_name = nil
              loop do
                  new_name = rand(2**16).to_s
                  break unless self.class.is_name_used?(new_name)
                  sleep(0.01)
              end
              name = new_name
          end
          
          # Save network info
          @name = name
          
          # Get variables to store message
          @in_commands = [].extend(MonitorMixin)
          
          self.open
      end
      
      def full_name
          self.class.file_path + @name
      end
      
      def self.file_path
          $TempCommunicationDirectory
      end
      
      def self.is_name_used?(name)
          full_name = file_path + name
          retval = false
          
          # If the file exist, and we can connect to it, it is used
          if File.exist?(full_name)
              s = nil
              begin
                  s = UNIXSocket.new(full_name)
                  retval = false
              rescue
                  retval = true
              ensure
                  s.close if s
              end
          end
          
          return retval
      end
      
      # Will block until the next command is received, then return it
      def wait_for_any_command
          loop do
             message = nil
             @in_commands.synchronize do
                 if @in_commands.length > 0
                     message = @in_commands.shift
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
      def wait_for_command(command, max_seconds_to_wait=5)          
          start_time = Time.now

          retval = nil
          loop do
              @in_commands.synchronize do
                  @in_commands.each do |user_command|
                      if user_command[:command] == command
                          retval = @in_commands.delete(user_command)
                          break
                      end
                  end
              end
              break if retval
              raise "Timed out while waiting for the command '#{command}'" if (Time.now - start_time).to_i > max_seconds_to_wait
              sleep(0.01)
          end
          
          return retval
      end            
      
        def send(dest_name, message)
            # Make sure the socket is open
            raise "The outgoing channel is closed" unless @is_open
                    
            # Make sure the arguments are valid
            raise "The message to send cannot be nil" unless message
            raise "The destination name cannot be nil" unless dest_name
            
            # Get the complete connection info
            complete_message = message.merge({:source_connection => @name, 
                                              :dest_connection => dest_name})
            
            # Get the message into YAML format
            message_yaml = YAML.dump(complete_message)

            # Send the message to the destination
            out_socket = nil
            begin
                out_socket = UNIXSocket.new(self.class.file_path + complete_message[:dest_connection])
                out_socket.write message_yaml
            rescue Exception
                raise "No connection named '#{dest_name}' to send to."
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
              @in_socket = UNIXServer.new(self.full_name)
          rescue Errno::EADDRINUSE
             raise "The name '#{@name}' is already used by a service."
          end
              
          @in_thread = Thread.new do
              @is_incoming_open = true
              while @is_incoming_open
                  result = nil
                  begin
                      sock = @in_socket.accept_nonblock
                      result = YAML.load(sock.read)
                  rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
                      IO.select([@in_socket])
                      retry
                  end

                  raise "Incoming message not a Hash." unless result.class == Hash
                  raise "Incoming message missing source_connection." unless result.has_key?(:source_connection)
                  raise "Incoming message missing dest_connection." unless result.has_key?(:dest_connection)
                  
                  @in_commands.synchronize { @in_commands << result }
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
          File.delete(self.full_name) if File.exist?(self.full_name)
          @in_commands.clear
      end
      
      def validate_connection(connection)
            if connection[:name] != @name
                raise "The connection does not belong to this Communication Controller"
            end
        end
    end
end

