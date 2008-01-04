
require 'monitor'
require 'socket'
require 'fileutils'

module ID; module Controllers
    class SystemCommunicationController
      attr_reader :name, :is_open, :is_incoming_open, :is_outgoing_open
      
      def initialize(name = :random)
          # Make sure the temp directory exist
          FileUtils.mkdir(self.class.file_path) unless File.directory?(self.class.file_path)
          
          # Validate arguments
          raise "The name cannot be nil" unless name
          raise "The name '#{name}' is already used by a service." if name != :random && self.class.is_name_used?(name)
          
          # Generate a random name if it was :random
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
          @waiting_for_any = nil
          @waiting_for_command = {}.extend(MonitorMixin)
          
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
          
          # Just return false if the file does not exist
          return false unless File.exist?(full_name)
          
          # If we can connect to the file, it is used
          retval = true
          begin
              s = UNIXSocket.new(full_name)
              retval = false
          rescue Exception => e
              retval = true
          ensure
              s.close if s
              File.delete(full_name) if File.exist?(full_name)
          end
          
          return retval
      end
      
      def self.get_socket_file_name(name)
          file_path + name
      end
      
      # Will block until the next command is received, then return it
      def wait_for_any_command
          # Make sure no block was given
          raise "This method does not except a block." if block_given?
              
          t = Thread.new do
            curr_thread = Thread.current
            @waiting_for_any =  Thread.current
        
            # Stop this thread, so it can be awoken by the incoming message
            Thread.stop
          end
        
          t.join()
          @waiting_for_any = nil
          return t[:command]
      end            
      
      # Will wait for a command up to a certain amount of time before throwing
      def wait_for_command(command, max_seconds_to_wait=10)
          # Make sure no block was given
          raise "This method does not except a block." if block_given?
          
          t = Thread.new do
            curr_thread = Thread.current
            @waiting_for_command[command.to_s] =  curr_thread
        
            # Stop this thread, so it can be awoken by the incoming message
            Thread.stop
          end
        
          timeout_thread = Thread.new do
              sleep max_seconds_to_wait
              raise "Timed out while waiting for the command '#{command}'"
          end
        
          t.join()
          timeout_thread.kill()
          @waiting_for_command.delete(command.to_s)
          return t[:command]
      end            
      
        def send_command(dest_name, message)
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
          if @is_open
              stop_incoming_thread
              @is_open = false
          end
          
          File.delete(self.full_name) if File.exist?(self.full_name)
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
                      # Get the yamled data from the socket
                      sock = @in_socket.accept_nonblock
                      yamled_data = sock.read
                      sock.close
                      
                      # Get the data from the yaml if there is any
                      next if yamled_data.length == 0
                      result = YAML.load(yamled_data)
                  rescue Errno::EAGAIN, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
                      IO.select([@in_socket])
                      retry
                  end

                  raise "Message incoming to '#{name}' is not a Hash." unless result.class == Hash
                  raise "Message incoming to '#{name}' is missing source_connection." unless result.has_key?(:source_connection)
                  raise "Message incoming to '#{name}' is missing dest_connection." unless result.has_key?(:dest_connection)
                  raise "Message incoming to '#{name}' is missing a command." unless result.has_key?(:command)
                  
                  thread = nil
                  if @waiting_for_any != nil
                      thread = @waiting_for_any
                  elsif @waiting_for_command.has_key?(result[:command].to_s)
                      thread = @waiting_for_command.delete(result[:command].to_s)
                  else
                      raise "Message '#{result[:command].to_s}' incoming to '#{name}' was not expected."
                  end
                  thread[:command]  = result
                  thread.run()
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
          @waiting_for_any = nil
          @waiting_for_command = {}.extend(MonitorMixin)
      end
      
      def validate_connection(connection)
            if connection[:name] != @name
                raise "The connection does not belong to this Communication Controller"
            end
        end
    end
end; end

