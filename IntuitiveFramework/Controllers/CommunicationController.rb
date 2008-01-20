

module ID; module Controllers
    # Basically a system socket that relays all its messages through the communication server.
    class CommunicationController
	    attr_reader :is_open
      
	    def initialize(name)
          raise "The name parameter must be a string." unless name.is_a? String
          @name = name
          
	        # Validate arguments
          raise "The name parameter cannot be nil" unless @name
          if @name != :random
              raise "The name '#{@name}' is already used by a service." if Servers::CommunicationServer.is_name_used?(@name)
          end
          
          # Generate a random name if it was :random
          @name = Helpers::EasySocket.get_random_unused_name if @name == :random
          
          @name = @name.to_s
          
          # Get variables to store message
          @waiting_for_any = nil
          @waiting_for_command = {}.extend(MonitorMixin)
          
          self.open
	    end
      
      def mode
          @in_socket.mode
      end
      
      def name
          @name
      end
      
      def ip_address
          @in_socket.ip_address
      end
      
      def port
          @in_socket.port
      end
      
      def full_address
          @in_socket.full_address
      end
      
      def file_name
          Servers::CommunicationServer.file_path + @name
      end
      
      # Will block until the next command is received, then return it
      def wait_for_any_command
          # Make sure no block was given
          raise "This method expects a block." unless block_given?
              
          t = Thread.new do
            curr_thread = Thread.current
            @waiting_for_any =  Thread.current
        
            # Stop this thread, so it can be awoken by the incoming message
            Thread.stop
          end
        
          t.join()
          @waiting_for_any = nil
          yield t[:command]
      end            
      
      # Will wait for a command up to a certain amount of time before throwing
      def wait_for_command(command, max_seconds_to_wait=10)
          # Make sure no block was given
          raise "This method expects a block." unless block_given?
          
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
          yield t[:command]
      end         
	    
        def send_command(message)
            # Make sure the socket is open
            raise "The outgoing channel is closed" unless @is_open
                    
            # Make sure the arguments are valid
            raise "The message to send was nil" unless message
            raise "The command to send was nil" unless message[:command]
            
            # Add the source to the message
            complete_message = message.clone
            complete_message.merge! :source => @name
            
            # Move the real destination to the :real_destination
            complete_message.merge! :real_destination => complete_message.delete(:destination)
            
            # Set the communication server as the :destination
            complete_message.merge! :destination => {:name => "CommunicationServer"}
            
            # Send a message to the communication server that will forward it to the destination
            source_socket = Helpers::EasySocket.new(:name => :random)
            source_socket.write_message(complete_message)
            source_socket.close
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
          @in_thread = Thread.new do
              @in_socket = Helpers::EasySocket.new(:name => @name)
              
              @in_socket.read_messages do |message|
                  message = YAML.load(message)
	                raise "Incoming message not a Hash." unless message.class == Hash
	                raise "Incoming message missing source_connection." unless message.has_key?(:source)
	                raise "Incoming message missing dest_connection." unless message.has_key?(:destination)
                  raise "Message incoming to '#{@ip_address}:#{@in_port}' is missing a command." unless message.has_key?(:command)
	                
                  thread = nil
                  if @waiting_for_any != nil
                      thread = @waiting_for_any
                  elsif @waiting_for_command.has_key?(message[:command].to_s)
                      thread = @waiting_for_command.delete(message[:command].to_s)
                  else
                      raise "Message '#{message[:command].to_s}' incoming to '#{@name}' was not expected."
                  end
                  thread[:command]  = message
                  thread.run()
              end
	        end
          
          @is_incoming_open = true
	    end
	    
	    def stop_incoming_thread
	        @is_incoming_open = false
	        @in_socket.close
          @in_thread.exit
	    end
    end
end; end

