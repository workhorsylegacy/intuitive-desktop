
require $IntuitiveFramework_Helpers

module ID; module Servers
    class CommunicationServer
        attr_reader :is_open, :ip_address, :port, :system_name, :on_error
        
        def initialize(on_error)
            # Make sure the on_error is valid
            on_error_options = [:log_to_file, :log_to_std_error, :throw]
            message = "The Communication Server can only use #{on_error_options.join(', ')} for on_error."
            raise message unless on_error_options.include? on_error.to_sym
            @on_error = on_error
            
            @is_open = false
            @ip_address = ID::Config.ip_address
            @port = ID::Config.port
            @system_name = "CommunicationServer"

            self.open
        end
        
        def open
            # Just return if it is already open
            return if @is_open
            
            @is_open = true
            start_threads
        end
        
        def close
            # Just return if it is already closed
            return unless @is_open
            
            @is_open = false
            stop_threads
        end
        
        def self.file_path
          ID::Config.comm_dir
        end
        
        def full_address
            retval = {}
            retval.merge!(:ip_address => @ip_address) if @ip_address
            retval.merge!(:port => @port) if @port
            retval.merge!(:name => @system_name)
            retval
        end
        
        def self.full_name
            file_path + @system_name
        end
      
      def self.is_name_used?(name)
          File.exist? file_path + name.to_s
      end
        
        private
        
        def stop_threads
            @system_socket.close
            @net_socket.close
            @system_thread.kill
            @net_thread.kill
        end
        
        def start_threads
            @system_socket = Helpers::EasySocket.new(:name => @system_name)
            @system_thread = Thread.new do
                @system_socket.read_messages do |message_as_yaml|
                    forward_message(message_as_yaml)
                end
            end
            
            @net_socket = Helpers::EasySocket.new(:ip_address => @ip_address, :port => @port)
            @net_thread = Thread.new do
                @net_socket.read_messages do |message_as_yaml|
                    forward_message(message_as_yaml)
                end
            end
        end 
       
        private
        
        def forward_message(message_as_yaml)
            message_as_ruby = YAML.load(message_as_yaml)
            
            # Make sure the message is valid
            raise "The message is not a Hash." unless message_as_ruby.class == Hash
            raise "The message is missing the source." unless message_as_ruby.has_key?(:source)
            raise "The message is missing the destination." unless message_as_ruby.has_key?(:destination)
            raise "The message is missing the real destination." unless message_as_ruby.has_key?(:real_destination)
            raise "The message is missing the command." unless message_as_ruby.has_key?(:command)
                  
            # Determine if we are sending to a local socket, or remote socket
            destination = message_as_ruby[:destination]
            is_remote = destination.has_key?(:ip_address) && destination.has_key?(:port)
                  
            # Make sure the destination exist if it is local
            unless is_remote
                dest_name = destination[:name]
                raise "No system destination named '#{dest_name}' to send to." unless self.class.is_name_used?(dest_name)
            end
             
            # Change the destination to be the real destination
            complete_message = message_as_ruby.clone
            complete_message[:routing] ||= []
            complete_message[:routing] << {:name => "CommunicationServer"}
            complete_message[:destination] = complete_message.delete(:real_destination)
            
            # If the destination is a net socket with the address of this communication server 
            # remove the ip address and port, so it won't get relayed back to here again
            destination = complete_message[:destination]
            if destination[:ip_address] == @net_socket.ip_address &&
               destination[:port] == @net_socket.port
               destination.delete(:ip_address)
               destination.delete(:port)
            end
            
            # Forward the message to the dest socket socket
            out_socket = Helpers::EasySocket.new(:name => :random)
            out_socket.write_message(complete_message)
            out_socket.close()
        end
    end
end; end

