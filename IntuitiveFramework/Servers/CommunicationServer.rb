
require 'monitor'
require 'socket'
require 'fileutils'

module ID; module Servers
    class CommunicationServer
        attr_reader :is_open, :ip_address, :port, :system_name, :on_error
#        def self.force_kill_other_instances
#            return unless Controllers::SystemCommunicationController.is_system_name_used?("CommunicationServer")
#            
#            unix_socket_file = Controllers::SystemCommunicationController.get_socket_file_name("CommunicationServer")
#            File.delete(unix_socket_file) if File.exist?(unix_socket_file)
#        end
        
        def initialize(ip_address, in_port, use_local_web_service, on_error)
            # Make sure the on_error is valid
            on_error_options = [:log_to_file, :log_to_std_error, :throw]
            message = "The Communication Server can only use #{on_error_options.join(', ')} for on_error."
            raise message unless on_error_options.include? on_error.to_sym
            @on_error = on_error
            
            @is_open = false
            @ip_address = ip_address
            @port = port
            @system_name = "CommunicationServer"

            self.open
        end
        
        def open
            # Just return if it is already open
            return if @is_open
            
            @is_open = true
            self.start_system_thread
            self.start_net_thread
        end
        
        def close
            # Just return if it is already closed
            return unless @is_open
            
            @is_open = false
            self.stop_net_thread
            self.stop_system_thread
        end
        
        def self.file_path
          $TempCommunicationDirectory
        end
      
      def self.is_system_name_used?(name)
          full_name = file_path + name + ":system"
          return File.exist?(full_name)
      end
        
      def self.is_net_name_used?(name)
          full_name = file_path + name + ":net"
          return File.exist?(full_name)
      end
        
        private
        
        def start_system_thread
            socket = Helpers::EasySocket(:system)
            
            socket.read_messages(:name => self.full_name) do |message_as_yaml|
                forward_message(message_as_yaml, :system)
            end
        end
        
        def start_net_thread
            socket = Helpers::EasySocket(:net)
            
            socket.read_messages(:ip_address => @ip_address, :port => @port) do |message_as_yaml|
                forward_message(message_as_yaml, :net)
            end
        end 
       
        def forward_message(message_as_yaml, type)
            message_as_ruby = YAML.load(message_as_yaml)
            
            # Make sure the message is valid
            raise "Message incoming to '#{name}' is not a Hash." unless message_as_ruby.class == Hash
            raise "Message incoming to '#{name}' is missing source_connection." unless message_as_ruby.has_key?(:source_connection)
            raise "Message incoming to '#{name}' is missing dest_connection." unless message_as_ruby.has_key?(:dest_connection)
            raise "Message incoming to '#{name}' is missing a command." unless message_as_ruby.has_key?(:command)
                  
            # Make sure the communication controller exits and is set to accept system messages
            dest_name = message_as_ruby[:dest_connection]
            destination_exist =
            case type
                when :net: is_net_name_used(dest_name)
                when :system: is_system_name_used(dest_name)
            end
            raise "No communication controller named '#{dest_name}' to send to." unless destination_exist
                  
            # Forward the message to the communication controller's unix socket
            out_socket = Helpers::EasySocket.new(:system)
            out_socket.write(message_as_yaml, {:name => self.file_name + message_as_ruby[:destination] + ":system"})
        end
        
=begin
        # FIXME: This should not be in the communication server
        def run_project(message)
            # Get the information
            remote_connection = message[:source_connection]
            project_number = message[:project_number]
            branch_number = message[:branch_number]

            # Create another connection just for this conversation and tell the remote machine to use it
            temp_connection = self.create_net_connection
            message = {:command => :ok_to_run_project, :new_connection => temp_connection}
            self.send_net_message(temp_connection, remote_connection, message)
            
            # Confirm that the client is using the new connection
            self.wait_for_message(temp_connection, :confirm_new_connection)
            
            # Get the Project
            branch = Models::Branch.from_number(branch_number)
            project = Models::Project.from_number(branch, project_number)
            
            # Create the Models
            new_models = nil
            begin
                new_models = Models::Data::XmlModelCreator::models_from_documents(project.document_models)
            rescue Exception => e
                raise "Could not load the document's models because: " + e.message
            end
            
            # Make the Models available to proxy through the connection
            models_connections =
            new_models.collect do |name, model|
                Helpers::Proxy.make_object_proxyable(model)
            end                               
            
            # Create the Controller
            new_controller = nil
            begin
                project.document_controllers.each { |document| Kernel.eval(document.data) }
                new_controller = Kernel.eval(project.main_controller_class_name).new(new_models)
            rescue Exception => e
                raise "Could not load the document's controller because: " + e.message
            end
            
            # Make the Controller available to proxy through the connection
            controller_connection = Helpers::Proxy.make_object_proxyable(new_controller)
            # Send the client a connection for talking to the Model and Controller
            message = {:command => :got_model_and_controller_connections,
                        :model_connections => models_connections,
                        :main_controller_connection => controller_connection,
                        :document_states => project.document_states,
                        :document_views => project.document_views,
                        :main_view_name => project.main_view_name}
            self.send_net_message(temp_connection, remote_connection, message)
            
            # Remove the temporary connection
            self.destroy_net_connection(temp_connection)
        end 
=end
    end
end; end

